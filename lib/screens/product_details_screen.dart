import 'package:flutter/material.dart';

import '../models/item.dart';
import '../widgets/shop_controls.dart';

/// Product details in the PrelimExam style: image beside the info on wide
/// screens, stacked on narrow ones.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final image = ItemImage(url: item.imageUrl, height: 280);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.name, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          item.displayPrice ?? 'No price',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          item.description ?? 'No description.',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('DETAILS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 600
                      ? Row(
                          children: [
                            Expanded(child: image),
                            const SizedBox(width: 32),
                            Expanded(child: info),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [image, const SizedBox(height: 24), info],
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
