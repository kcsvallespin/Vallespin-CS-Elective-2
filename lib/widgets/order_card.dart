import 'package:flutter/material.dart';

import '../models/shop_order.dart';
import '../utils/format.dart';

/// One order: number, status, date, (customer), items and total.
/// [trailing] holds the admin's status dropdown.
class OrderCard extends StatelessWidget {
  const OrderCard({
    required this.order,
    this.showCustomer = false,
    this.trailing,
    super.key,
  });

  final ShopOrder order;
  final bool showCustomer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                trailing ?? StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(formatDate(order.createdAt), style: muted),
            if (showCustomer) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [order.customerName, order.customerEmail]
                          .whereType<String>()
                          .join(' · '),
                      style: muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            if (order.items.isEmpty)
              Text('No items.', style: muted)
            else
              for (final line in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${line.productName}  ×${line.quantity}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${formatMoney(line.unitPrice)} each',
                        style: muted,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: Text(
                          formatMoney(line.subtotal),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
            const Divider(height: 24),
            Row(
              children: [
                Text('${order.itemCount} item(s)', style: muted),
                const Spacer(),
                Text('Total  ', style: theme.textTheme.titleSmall),
                Text(
                  formatMoney(order.total),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      'done' || 'delivered' => (colors.primaryContainer, colors.onPrimaryContainer),
      'cancelled' => (colors.errorContainer, colors.onErrorContainer),
      _ => (colors.secondaryContainer, colors.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
