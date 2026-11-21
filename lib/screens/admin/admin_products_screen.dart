import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../utils/errors.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shop_controls.dart';
import '../../widgets/status_message.dart';
import 'admin_orders_screen.dart';
import 'categories_screen.dart';
import 'product_form_screen.dart';

/// Admin home: the product list with an Add button and Edit / Delete on
/// every card, plus links to categories and orders.
class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  void _openForm(BuildContext context, [Product? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Delete "${product.name}"?'),
        content: Text(
          '"${product.name}" will be permanently removed from the shop. '
          'Past orders keep their copy of its name and price.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(productsControllerProvider.notifier).delete(product);
      if (context.mounted) showSnack(context, 'Deleted "${product.name}"');
    } catch (e) {
      if (context.mounted) {
        showSnack(context, 'Delete failed: ${errorMessage(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products'),
            Text('ADMIN', style: TextStyle(fontSize: 11, letterSpacing: 1.5)),
          ],
        ),
        bottom: busyIndicator(state),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categories',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Orders',
          ),
          const ThemeToggleButton(),
          const SignOutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.saving ? null : () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      bottomNavigationBar: const PaginationBar(),
      body: Column(
        children: [
          const SearchAndCategoryBar(),
          const PriceFilterBar(),
          Expanded(
            child: AbsorbPointer(
              absorbing: state.saving,
              child: ProductsStateView(
                emptyMessage: 'No products yet. Tap "Add product" to create '
                    'the first one.',
                builder: (context, products) => ProductGrid(
                  products: products,
                  itemBuilder: (context, product) => ProductCard(
                    product: product,
                    onTap: () => _openForm(context, product),
                    footer: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openForm(context, product),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed: () =>
                              _confirmDelete(context, ref, product),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
