import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/orders_provider.dart';
import '../../widgets/order_card.dart';
import '../../widgets/status_message.dart';

/// The signed-in customer's own orders, newest first, with status, date,
/// total and items.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: AsyncValueView(
        value: orders,
        onRetry: () => ref.invalidate(myOrdersProvider),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(myOrdersProvider.future),
          child: list.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: const StatusMessage(
                        icon: Icons.receipt_long_outlined,
                        message: "You haven't placed any orders yet.",
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: OrderCard(order: list[i]),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
