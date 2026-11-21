import 'package:flutter/material.dart';

import '../models/product.dart';
import 'product_image.dart';

/// Product card for the grid. The [footer] differs by role: "Add to cart"
/// for customers, Edit / Delete for admins.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.footer,
    this.onTap,
    super.key,
  });

  final Product product;
  final Widget footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(child: ProductImage(url: product.imageUrl)),
              ),
              const SizedBox(height: 8),
              if (product.categoryName != null)
                Text(
                  product.categoryName!.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                product.name,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.displayPrice,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StockLabel(stock: product.stock),
                ],
              ),
              const SizedBox(height: 8),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// "12 left" / "Out of stock" in a small colored label.
class StockLabel extends StatelessWidget {
  const StockLabel({required this.stock, super.key});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final out = stock <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: out ? colors.errorContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        out ? 'Out of stock' : '$stock left',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: out ? colors.onErrorContainer : colors.onSecondaryContainer,
            ),
      ),
    );
  }
}
