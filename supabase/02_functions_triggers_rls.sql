-- Functions, the sign-up trigger, the checkout function, and Row Level
-- Security. Run after 01_schema.sql. Safe to re-run.
--
-- Why this matters: hiding admin buttons in the app is not security. Anyone
-- can call the Supabase API directly with the public key, so every rule
-- below is enforced by Postgres itself.

begin;

-- =========================================================
-- 1. Helper: is the signed-in user an admin?
-- =========================================================
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    join public.roles r on r.id = p.role_id
    where p.id = auth.uid()
      and r.role = 'admin'
  );
$$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- =========================================================
-- 2. Profile creation: every new sign-up (email or Google)
--    gets a profile with the CUSTOMER role.
-- =========================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  meta      jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  full_name text  := trim(coalesce(meta->>'full_name', meta->>'name', ''));
begin
  insert into public.profiles (id, email, firstname, lastname, role_id)
  values (
    new.id,
    new.email,
    coalesce(nullif(meta->>'firstname', ''),
             nullif(meta->>'given_name', ''),
             nullif(split_part(full_name, ' ', 1), '')),
    coalesce(nullif(meta->>'lastname', ''),
             nullif(meta->>'family_name', ''),
             case when position(' ' in full_name) > 0
                  then nullif(trim(substring(full_name from position(' ' in full_name) + 1)), '')
             end),
    (select id from public.roles where role = 'customer')  -- never taken from the client
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill profiles for accounts that already exist.
insert into public.profiles (id, email, firstname, role_id)
select u.id,
       u.email,
       nullif(split_part(coalesce(u.raw_user_meta_data->>'full_name',
                                  u.raw_user_meta_data->>'name', ''), ' ', 1), ''),
       (select id from public.roles where role = 'customer')
from auth.users u
on conflict (id) do nothing;

-- =========================================================
-- 3. Checkout: saves the order + items, reduces stock and
--    marks it done in ONE transaction. The app sends only
--    product ids and quantities; names, prices and stock
--    come from the database.
-- =========================================================
create or replace function public.place_order(items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid          uuid := auth.uid();
  new_order_id bigint;
  order_total  numeric(12,2) := 0;
  line         record;
  prod         record;
  unit         numeric(12,2);
begin
  if uid is null then
    raise exception 'You must be signed in to place an order.' using errcode = '42501';
  end if;
  if public.is_admin() then
    raise exception 'Admins cannot place orders.' using errcode = '42501';
  end if;
  if not exists (select 1 from public.profiles where id = uid) then
    raise exception 'Your profile was not found.' using errcode = '42501';
  end if;
  if items is null or jsonb_typeof(items) <> 'array' or jsonb_array_length(items) = 0 then
    raise exception 'Your cart is empty.' using errcode = '22023';
  end if;

  insert into public.orders (user_id, status, total)
  values (uid, 'pending', 0)
  returning id into new_order_id;

  for line in
    select (e->>'product_id')::bigint   as product_id,
           sum((e->>'quantity')::int)   as quantity
    from jsonb_array_elements(items) e
    group by 1
    order by 1
  loop
    if line.product_id is null or line.quantity is null or line.quantity <= 0 then
      raise exception 'Invalid item in cart.' using errcode = '22023';
    end if;

    select p.id, p.name, p.price, p.stock
      into prod
      from public.products p
     where p.id = line.product_id
       for update;

    if not found then
      raise exception 'A product in your cart no longer exists.' using errcode = 'P0002';
    end if;
    if prod.stock < line.quantity then
      raise exception 'Not enough stock for "%": % left, % requested.',
        prod.name, prod.stock, line.quantity using errcode = '23514';
    end if;

    unit := round(prod.price::numeric, 2);

    update public.products
       set stock = stock - line.quantity
     where id = prod.id;

    insert into public.order_items (order_id, product_id, product_name, unit_price, quantity)
    values (new_order_id, prod.id, prod.name, unit, line.quantity);

    order_total := order_total + unit * line.quantity;
  end loop;

  update public.orders
     set total = order_total,
         status = 'done'
   where id = new_order_id;

  return jsonb_build_object('order_id', new_order_id, 'total', order_total);
end;
$$;
revoke all on function public.place_order(jsonb) from public, anon;
grant execute on function public.place_order(jsonb) to authenticated;

-- =========================================================
-- 4. Row Level Security
-- =========================================================
do $$
declare pol record;
begin
  for pol in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('profiles','roles','categories','products','orders','order_items')
  loop
    execute format('drop policy %I on %I.%I', pol.policyname, pol.schemaname, pol.tablename);
  end loop;
end $$;

alter table public.profiles    enable row level security;
alter table public.roles       enable row level security;
alter table public.categories  enable row level security;
alter table public.products    enable row level security;
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

-- Signed out: no access at all.
revoke all on public.profiles, public.roles, public.categories,
              public.products, public.orders, public.order_items from anon;

-- profiles: customer reads/updates own row (never the role); admin reads all.
create policy "profiles: read own"
  on public.profiles for select to authenticated
  using (id = auth.uid());
create policy "profiles: admin reads all"
  on public.profiles for select to authenticated
  using (public.is_admin());
create policy "profiles: update own"
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
revoke insert, update, delete on public.profiles from authenticated;
grant update (firstname, lastname) on public.profiles to authenticated;

-- roles: read only.
create policy "roles: signed-in read"
  on public.roles for select to authenticated
  using (true);
revoke insert, update, delete on public.roles from authenticated;

-- categories: everyone signed in reads; admin writes.
create policy "categories: signed-in read"
  on public.categories for select to authenticated
  using (true);
create policy "categories: admin insert"
  on public.categories for insert to authenticated
  with check (public.is_admin());
create policy "categories: admin update"
  on public.categories for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy "categories: admin delete"
  on public.categories for delete to authenticated
  using (public.is_admin());

-- products: everyone signed in reads; admin writes.
create policy "products: signed-in read"
  on public.products for select to authenticated
  using (true);
create policy "products: admin insert"
  on public.products for insert to authenticated
  with check (public.is_admin());
create policy "products: admin update"
  on public.products for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy "products: admin delete"
  on public.products for delete to authenticated
  using (public.is_admin());

-- orders: customer reads own; admin reads all + updates status.
-- Nobody inserts directly; orders are created only by place_order().
create policy "orders: customer reads own"
  on public.orders for select to authenticated
  using (user_id = auth.uid());
create policy "orders: admin reads all"
  on public.orders for select to authenticated
  using (public.is_admin());
create policy "orders: admin updates status"
  on public.orders for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
revoke insert, update, delete on public.orders from authenticated;
grant update (status) on public.orders to authenticated;

-- order_items: customer reads items of own orders; admin reads all.
create policy "order_items: customer reads own"
  on public.order_items for select to authenticated
  using (exists (
    select 1 from public.orders o
    where o.id = order_items.order_id
      and o.user_id = auth.uid()
  ));
create policy "order_items: admin reads all"
  on public.order_items for select to authenticated
  using (public.is_admin());
revoke insert, update, delete on public.order_items from authenticated;

-- =========================================================
-- 5. Storage: only admins can upload/replace/delete images.
-- =========================================================
do $$
declare pol record;
begin
  for pol in
    select policyname from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and (coalesce(qual, '') || coalesce(with_check, '')) like '%item-images%'
  loop
    execute format('drop policy %I on storage.objects', pol.policyname);
  end loop;
end $$;

create policy "item-images: signed-in read"
  on storage.objects for select to authenticated
  using (bucket_id = 'item-images');
create policy "item-images: admin upload"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'item-images' and public.is_admin());
create policy "item-images: admin update"
  on storage.objects for update to authenticated
  using (bucket_id = 'item-images' and public.is_admin())
  with check (bucket_id = 'item-images' and public.is_admin());
create policy "item-images: admin delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'item-images' and public.is_admin());

commit;

-- Make an account an admin (run separately, with the real email):
-- update public.profiles
-- set role_id = (select id from public.roles where role = 'admin')
-- where email = 'admin@example.com';
