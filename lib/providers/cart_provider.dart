import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import 'auth_provider.dart';

class CartState {
  final List<CartItem> items;

  const CartState([this.items = const []]);

  bool get isEmpty => items.isEmpty;

  /// Total number of units across all lines.
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get total => items.fold(0, (sum, i) => sum + i.subtotal);

  int quantityOf(int productId) {
    for (final item in items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }
}

enum AddToCartResult { added, outOfStock, stockLimitReached }

/// The shopping cart, held in app state so it survives screen changes.
/// It is emptied after a successful order and whenever the signed-in user
/// changes (including logout).
final cartControllerProvider =
    NotifierProvider<CartController, CartState>(CartController.new);

class CartController extends Notifier<CartState> {
  @override
  CartState build() {
    // Rebuilding on a user change resets the cart to empty.
    ref.watch(currentUserIdProvider);
    return const CartState();
  }

  /// Adds one unit. Refuses out-of-stock products and quantities above the
  /// available stock. (The database checks stock again at checkout.)
  AddToCartResult add(Product product) {
    if (!product.inStock) return AddToCartResult.outOfStock;
    final current = state.quantityOf(product.id);
    if (current >= product.stock) return AddToCartResult.stockLimitReached;
    if (current == 0) {
      state = CartState([
        ...state.items,
        CartItem(product: product, quantity: 1),
      ]);
    } else {
      // Store the freshest product data (stock may have changed).
      state = CartState([
        for (final item in state.items)
          item.product.id == product.id
              ? CartItem(product: product, quantity: current + 1)
              : item,
      ]);
    }
    return AddToCartResult.added;
  }

  /// Sets a line's quantity, clamped to 1..stock. Zero or less removes it.
  void setQuantity(int productId, int quantity) {
    if (quantity <= 0) return remove(productId);
    _replace(productId, quantity);
  }

  void remove(int productId) {
    state = CartState([
      for (final item in state.items)
        if (item.product.id != productId) item,
    ]);
  }

  void clear() => state = const CartState();

  void _replace(int productId, int quantity) {
    state = CartState([
      for (final item in state.items)
        if (item.product.id == productId)
          item.copyWith(
            quantity: quantity.clamp(1, item.product.stock).toInt(),
          )
        else
          item,
    ]);
  }
}
