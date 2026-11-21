import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/shop_order.dart';
import '../utils/format.dart';

/// Checkout and order queries.
class OrderService {
  OrderService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  static const _table = 'orders';
  static const _itemsSelect =
      'order_items(id, product_id, product_name, unit_price, quantity)';

  final SupabaseClient _client;

  /// Places an order through the `place_order` database function.
  ///
  /// Only product ids and quantities are sent. The function reads names,
  /// prices and stock from the database, saves the order and its items,
  /// reduces stock and marks the order done in one transaction: if anything
  /// fails, nothing is saved.
  Future<PlacedOrder> placeOrder(List<CartItem> items) async {
    final result = await _client.rpc(
      'place_order',
      params: {
        'items': [
          for (final item in items)
            {'product_id': item.product.id, 'quantity': item.quantity},
        ],
      },
    );
    final map = Map<String, dynamic>.from(result as Map);
    return PlacedOrder(
      orderId: (map['order_id'] as num).toInt(),
      total: parseDouble(map['total']),
    );
  }

  /// The signed-in customer's own orders, newest first.
  Future<List<ShopOrder>> fetchMyOrders(String userId) async {
    final rows = await _client
        .from(_table)
        .select('id, created_at, user_id, status, total, $_itemsSelect')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .order('id', ascending: true, referencedTable: 'order_items');
    return rows.map(ShopOrder.fromJson).toList();
  }

  /// Every order with its customer (admins only; RLS enforces this).
  Future<List<ShopOrder>> fetchAllOrders() async {
    final rows = await _client
        .from(_table)
        .select(
          'id, created_at, user_id, status, total, $_itemsSelect, '
          'profiles(email, firstname, lastname)',
        )
        .order('created_at', ascending: false)
        .order('id', ascending: true, referencedTable: 'order_items');
    return rows.map(ShopOrder.fromJson).toList();
  }

  /// Changes an order's status (admins only; RLS enforces this).
  Future<void> updateStatus(int orderId, String status) async {
    await _client
        .from(_table)
        .update({'status': status})
        .eq('id', orderId)
        .select('id')
        .single();
  }
}
