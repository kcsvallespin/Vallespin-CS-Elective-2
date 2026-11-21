import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../utils/errors.dart';
import '../../utils/format.dart';
import '../../widgets/product_image.dart';
import '../../widgets/status_message.dart';
import 'checkout_confirmation_screen.dart';

/// Cart: change quantities (up to stock), remove lines, see the running
/// total and item count, and check out.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final placed =
        await ref.read(checkoutControllerProvider.notifier).placeOrder();
    if (placed == null || !context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutConfirmationScreen(order: placed),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(checkoutControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        showSnack(context, 'Checkout failed: ${errorMessage(next.error!)}');
      }
    });

    final cart = ref.watch(cartControllerProvider);
    final placing = ref.watch(checkoutControllerProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${cart.itemCount})'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: placing
                  ? null
                  : () => ref.read(cartControllerProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? StatusMessage(
              icon: Icons.shopping_bag_outlined,
              message: 'Your cart is empty.',
              actionLabel: 'Browse products',
              actionIcon: Icons.storefront_outlined,
              onAction: () => Navigator.pop(context),
            )
          : AbsorbPointer(
              absorbing: placing,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _CartLine(item: cart.items[i]),
              ),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Material(
              color: theme.colorScheme.surfaceContainer,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cart.itemCount} item(s)',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              formatMoney(cart.total),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed:
                            placing ? null : () => _checkout(context, ref),
                        icon: placing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_outline),
                        label: Text(placing ? 'Placing order…' : 'Checkout'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.read(cartControllerProvider.notifier);
    final product = item.product;
    final atMax = item.quantity >= product.stock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                url: product.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${product.displayPrice} each · ${product.stock} in stock',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton.outlined(
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            cart.setQuantity(product.id, item.quantity - 1),
                        icon: const Icon(Icons.remove, size: 18),
                        tooltip: 'Decrease',
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton.outlined(
                        visualDensity: VisualDensity.compact,
                        onPressed: atMax
                            ? null
                            : () => cart.setQuantity(
                                  product.id,
                                  item.quantity + 1,
                                ),
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: atMax ? 'No more in stock' : 'Increase',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => cart.remove(product.id),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove',
                ),
                Text(
                  formatMoney(item.subtotal),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
