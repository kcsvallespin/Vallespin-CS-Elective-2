import 'product.dart';

/// One product line in the cart. Only [product.id] and [quantity] are sent
/// at checkout; prices and stock are re-read by the database.
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}
