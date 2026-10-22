import 'package:flutter/material.dart';

import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final bool isFavorite;
  final String? nickname;
  final VoidCallback onFavorite;
  final VoidCallback onEditNickname;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.isFavorite,
    required this.nickname,
    required this.onFavorite,
    required this.onEditNickname,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(pokemon.displayId, style: theme.textTheme.labelMedium),
                IconButton(
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Expanded(
              child: Image.network(
                pokemon.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Text(
              nickname ?? pokemon.displayName,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              pokemon.types.map(_capitalize).join(' / '),
              style: theme.textTheme.labelSmall,
            ),
            TextButton.icon(
              onPressed: onEditNickname,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Nickname'),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}
