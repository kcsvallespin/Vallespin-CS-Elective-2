import 'package:flutter/material.dart';

import '../models/item.dart';

/// Grid card for an item: image, name, and price.
/// Tap to edit; the corner button deletes.
class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ItemCard({super.key, required this.item, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Icon(
      Icons.inventory_2_outlined,
      size: 48,
      color: theme.colorScheme.outline,
    );

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.imageUrl == null
                          ? Center(child: placeholder)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (onDelete != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: onDelete,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.displayPrice ?? 'No price',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: item.price == null
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
