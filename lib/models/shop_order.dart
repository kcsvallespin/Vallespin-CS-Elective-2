import '../utils/format.dart';

/// Statuses an admin can set. Checkout sets new orders to "done".
const orderStatuses = [
  'pending',
  'done',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
];

/// A row in `order_items`: a snapshot of the product name and the unit price
/// paid, so past orders stay accurate when products change or are deleted.
class OrderLine {
  final int id;
  final int? productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  const OrderLine({
    required this.id,
    this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        id: json['id'] as int,
        productId: (json['product_id'] as num?)?.toInt(),
        productName: (json['product_name'] as String?) ?? 'Unknown product',
        unitPrice: parseDouble(json['unit_price']),
        quantity: (json['quantity'] as num).toInt(),
      );
}

/// A row in `orders` with its items (and, for admins, the customer).
class ShopOrder {
  final int id;
  final DateTime createdAt;
  final String userId;
  final String status;
  final double total;
  final List<OrderLine> items;
  final String? customerName;
  final String? customerEmail;

  const ShopOrder({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.status,
    required this.total,
    required this.items,
    this.customerName,
    this.customerEmail,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  ShopOrder copyWith({String? status}) => ShopOrder(
        id: id,
        createdAt: createdAt,
        userId: userId,
        status: status ?? this.status,
        total: total,
        items: items,
        customerName: customerName,
        customerEmail: customerEmail,
      );

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final name = [profile?['firstname'], profile?['lastname']]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    return ShopOrder(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      status: (json['status'] as String?) ?? 'pending',
      total: parseDouble(json['total']),
      items: ((json['order_items'] as List?) ?? const [])
          .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      customerName: name.isEmpty ? null : name,
      customerEmail: profile?['email'] as String?,
    );
  }
}

/// What `place_order` returns: the new order's number and total.
class PlacedOrder {
  final int orderId;
  final double total;

  const PlacedOrder({required this.orderId, required this.total});
}
