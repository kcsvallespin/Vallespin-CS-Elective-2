import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shop_order.dart';
import '../../providers/orders_provider.dart';
import '../../utils/errors.dart';
import '../../widgets/order_card.dart';
import '../../widgets/status_message.dart';

/// Admin list of every customer's orders, newest first, with a status
/// dropdown on each.
class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    ShopOrder order,
    String status,
  ) async {
    if (status == order.status) return;
    try {
      await ref
          .read(adminOrdersControllerProvider.notifier)
          .updateStatus(order, status);
      if (context.mounted) {
        showSnack(context, 'Order #${order.id} marked $status');
      }
    } catch (e) {
      if (context.mounted) {
        showSnack(context, 'Update failed: ${errorMessage(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersControllerProvider);
    final controller = ref.read(adminOrdersControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All orders'),
        actions: [
          IconButton(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: AsyncValueView(
        value: orders,
        onRetry: controller.refresh,
        data: (list) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: list.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: const StatusMessage(
                        icon: Icons.receipt_long_outlined,
                        message: 'No orders yet.',
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final order = list[i];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: OrderCard(
                          order: order,
                          showCustomer: true,
                          trailing: DropdownButton<String>(
                            value: orderStatuses.contains(order.status)
                                ? order.status
                                : null,
                            hint: Text(order.status),
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(12),
                            items: [
                              for (final s in orderStatuses)
                                DropdownMenuItem(
                                  value: s,
                                  child: StatusChip(status: s),
                                ),
                            ],
                            onChanged: (s) {
                              if (s != null) _setStatus(context, ref, order, s);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
