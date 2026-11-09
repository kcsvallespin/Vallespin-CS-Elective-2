import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/items_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_controls.dart';
import 'manage_items_screen.dart';
import 'product_details_screen.dart';

/// Customer-facing storefront: browse, filter by price, and page through
/// products. Editing lives on the separate Manage Items screen.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reniacc's Comission Services"),
        bottom: busyIndicator(state),
        actions: [
          IconButton(
            onPressed: () => ref.read(darkModeProvider.notifier).toggle(),
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageItemsScreen()),
            ),
            icon: const Icon(Icons.edit_note),
            tooltip: 'Manage items',
          ),
        ],
      ),
      bottomNavigationBar: const PaginationBar(),
      body: Column(
        children: [
          const PriceFilterBar(),
          Expanded(
            child: ItemsStateView(
              builder: (context, items) => LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    // 3 columns on wide screens, otherwise 2.
                    crossAxisCount: constraints.maxWidth >= 800 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: .72,
                  ),
                  itemBuilder: (context, index) => ProductCard(
                    item: items[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreen(item: items[index]),
                      ),
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
