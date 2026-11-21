import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_image.dart';

/// Product details: image beside the info on wide screens, stacked on
/// narrow ones, with an Add to cart button.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ProductImage(url: product.imageUrl, height: 300),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.categoryName != null)
          Text(
            product.categoryName!.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
        Text(product.name, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              product.displayPrice,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            StockLabel(stock: product.stock),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          (product.description?.trim().isNotEmpty ?? false)
              ? product.description!
              : 'No description.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        AddToCartButton(product: product),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: const [CartButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 600
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: image),
                            const SizedBox(width: 32),
                            Expanded(child: info),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [image, const SizedBox(height: 20), info],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
