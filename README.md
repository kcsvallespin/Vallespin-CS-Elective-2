# Reniacc's Commission Services: E-Commerce App

Flutter + Riverpod + Supabase shop with two roles. **Admins** manage the
catalog and orders, and **customers** browse, fill a cart and place orders.

## Features

| Role | What they can do |
|---|---|
| Signed out | Sign up / log in with email + password or Google |
| Customer | Search, filter by category and price, paginate, add to cart (limited by stock), checkout, view own order history |
| Admin | Add / edit / delete products (with image upload), manage categories, view all orders and change their status |

Every new account is a **customer**. To make an admin, run in the SQL Editor:

```sql
update public.profiles
set role_id = (select id from public.roles where role = 'admin')
where email = 'admin@example.com';
```

## Project structure

```
lib/
  models/      plain data classes (Product, ShopOrder, Profile, ...)
  services/    the ONLY code that talks to Supabase
  providers/   Riverpod state; screens call these, these call services
  screens/
    auth/      auth gate, login, sign up
    customer/  shop, product details, cart, checkout confirmation, order history
    admin/     products (FAB + edit/delete), product form, categories, orders
  widgets/     shared UI (product card, filters, order card, status messages)
  theme/       app-wide theme (light + dark)
  utils/       formatting and error messages
supabase/      SQL for the schema, functions, trigger and RLS policies
```

## Supabase setup

1. Run `supabase/01_schema.sql` in the SQL Editor (tables).
2. Run `supabase/02_functions_triggers_rls.sql` (profile trigger,
   `place_order` checkout function, RLS and storage policies).
3. Promote your admin account with the query above.

Security is enforced by Postgres, not by hiding buttons: RLS limits every
table to the permissions in the project brief, customers cannot change
their role, and orders can only be created through `place_order`. That
function reads prices, names and stock from the database, saves the order
and its items, and reduces stock in one transaction.

### Google sign-in setup

1. In Google Cloud Console, create a project and configure the OAuth consent
   screen (External; add your Gmail under Test users).
2. Create an OAuth client ID of type **Web application**:
   - Authorized JavaScript origins: `http://localhost:3000`
   - Authorized redirect URIs: `https://sbdptpmrtoztuovpjheq.supabase.co/auth/v1/callback`
3. In Supabase: Authentication > Sign In / Providers > Google, enable it and
   paste the Client ID and Secret.
4. In Supabase: Authentication > URL Configuration
   - Site URL: `http://localhost:3000`
   - Redirect URLs: `io.supabase.reniacc://login-callback/` and `http://localhost:3000/**`

### Run

```
flutter run --dart-define=SUPABASE_ANON_KEY=your-publishable-key
flutter run -d chrome --web-port 3000 --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```
