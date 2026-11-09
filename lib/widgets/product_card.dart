import 'package:flutter/material.dart';

import '../models/item.dart';
import 'shop_controls.dart';

/// Storefront card in the PrelimExam style: image, name, big price,
/// and a "VIEW DETAILS" row.
class ProductCard extends StatelessWidget {
  const ProductCard({required this.item, required this.onTap, super.key});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(child: ItemImage(url: item.imageUrl)),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.displayPrice ?? 'No price',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: item.price == null ? theme.colorScheme.outline : null,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text('VIEW DETAILS'),
                  Spacer(),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
