import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_project/models/product.dart';
import 'package:my_flutter_project/providers/auth_provider.dart';
import 'package:my_flutter_project/providers/cart_provider.dart';

Product _product({int id = 1, int stock = 3, double price = 10}) => Product(
      id: id,
      createdAt: DateTime(2026),
      name: 'Product $id',
      stock: stock,
      categoryId: 1,
      price: price,
    );

void main() {
  late ProviderContainer container;
  late StateProvider<String?> userId;

  setUp(() {
    userId = StateProvider<String?>((ref) => 'user-1');
    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => ref.watch(userId)),
      ],
    );
  });
  tearDown(() => container.dispose());

  CartController cart() => container.read(cartControllerProvider.notifier);
  CartState state() => container.read(cartControllerProvider);

  test('adds products and keeps a running total and count', () {
    cart().add(_product(id: 1, price: 10));
    cart().add(_product(id: 1, price: 10));
    cart().add(_product(id: 2, price: 5.5));

    expect(state().items.length, 2);
    expect(state().itemCount, 3);
    expect(state().total, 25.5);
  });

  test('refuses out-of-stock products', () {
    final result = cart().add(_product(stock: 0));
    expect(result, AddToCartResult.outOfStock);
    expect(state().isEmpty, isTrue);
  });

  test('never goes above available stock', () {
    final p = _product(stock: 2);
    expect(cart().add(p), AddToCartResult.added);
    expect(cart().add(p), AddToCartResult.added);
    expect(cart().add(p), AddToCartResult.stockLimitReached);

    cart().setQuantity(p.id, 99);
    expect(state().quantityOf(p.id), 2);
  });

  test('setting quantity to zero removes the line', () {
    final p = _product();
    cart().add(p);
    cart().setQuantity(p.id, 0);
    expect(state().isEmpty, isTrue);
  });

  test('cart is emptied when the user signs out', () {
    container.listen(cartControllerProvider, (_, _) {});
    cart().add(_product());
    expect(state().itemCount, 1);

    container.read(userId.notifier).state = null;
    expect(state().isEmpty, isTrue);
  });
}
