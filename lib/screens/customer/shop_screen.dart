import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shop_controls.dart';
import 'order_history_screen.dart';
import 'product_details_screen.dart';

/// Customer storefront: search, filter by category and price, page through
/// products and add them to the cart. No management controls here.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsControllerProvider);
    final name = ref.watch(profileProvider).valueOrNull?.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reniacc's Commissions",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (name != null)
              Text(
                'Hi, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        bottom: busyIndicator(state),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My orders',
          ),
          const CartButton(),
          const ThemeToggleButton(),
          const SignOutButton(),
        ],
      ),
      bottomNavigationBar: const PaginationBar(),
      body: Column(
        children: [
          const SearchAndCategoryBar(),
          const PriceFilterBar(),
          Expanded(
            child: ProductsStateView(
              emptyMessage: 'No products available yet. Check back soon!',
              builder: (context, products) => ProductGrid(
                products: products,
                itemBuilder: (context, product) => ProductCard(
                  product: product,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  ),
                  footer: AddToCartButton(product: product),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
