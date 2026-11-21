import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_order.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'products_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

/// The signed-in customer's own orders, newest first.
final myOrdersProvider = FutureProvider<List<ShopOrder>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(orderServiceProvider).fetchMyOrders(userId);
});

/// Places the cart as an order. The state holds the placed order, the
/// loading flag while it runs, or the error if it failed.
final checkoutControllerProvider =
    AsyncNotifierProvider<CheckoutController, PlacedOrder?>(
  CheckoutController.new,
);

class CheckoutController extends AsyncNotifier<PlacedOrder?> {
  @override
  FutureOr<PlacedOrder?> build() {
    ref.watch(currentUserIdProvider);
    return null;
  }

  /// Returns the placed order, or null if the cart was empty or it failed
  /// (the error is then in [state]).
  Future<PlacedOrder?> placeOrder() async {
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty || state.isLoading) return null;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(orderServiceProvider).placeOrder(cart.items),
    );

    final placed = state.valueOrNull;
    if (placed != null) {
      ref.read(cartControllerProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
    }
    // Stock changed (or our cart was stale), so reload the product list.
    unawaited(ref.read(productsControllerProvider.notifier).refresh());
    return placed;
  }
}

/// Every order, for the admin order list, with status updates.
final adminOrdersControllerProvider =
    AsyncNotifierProvider<AdminOrdersController, List<ShopOrder>>(
  AdminOrdersController.new,
);

class AdminOrdersController extends AsyncNotifier<List<ShopOrder>> {
  OrderService get _service => ref.read(orderServiceProvider);

  @override
  Future<List<ShopOrder>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    return ref.read(orderServiceProvider).fetchAllOrders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<ShopOrder>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_service.fetchAllOrders);
  }

  /// Errors are rethrown so the screen can show them.
  Future<void> updateStatus(ShopOrder order, String status) async {
    await _service.updateStatus(order.id, status);
    state = AsyncData([
      for (final o in state.valueOrNull ?? const <ShopOrder>[])
        o.id == order.id ? o.copyWith(status: status) : o,
    ]);
  }
}
