import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/pokemon_provider.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/status_message.dart';

class PokemonListScreen extends StatelessWidget {
  final PokemonService? service;

  const PokemonListScreen({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final child = const _PokemonListView();
    return service == null
        ? child
        : ProviderScope(
            overrides: [pokemonServiceProvider.overrideWithValue(service!)],
            child: child,
          );
  }
}

class _PokemonListView extends ConsumerWidget {
  const _PokemonListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPokemon = ref.watch(pokemonControllerProvider);
    final controller = ref.read(pokemonControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite),
            onPressed: asyncPokemon.hasValue
                ? () => _showFavorites(context, controller, asyncPokemon.value!)
                : null,
          ),
          IconButton(
            tooltip: 'Refresh Pokémon',
            icon: const Icon(Icons.refresh),
            onPressed: asyncPokemon.hasValue ? controller.refresh : null,
          ),
        ],
      ),
      body: asyncPokemon.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => StatusMessage(
          icon: Icons.wifi_off,
          message: 'Something went wrong while loading Pokémon.\n$error',
          actionLabel: 'Retry',
          onAction: controller.retry,
        ),
        data: (pokemon) {
          if (pokemon.isEmpty) {
            return StatusMessage(
              icon: Icons.catching_pokemon,
              message: 'No Pokémon found.',
              actionLabel: 'Reload',
              onAction: controller.retry,
            );
          }
          return _PokemonContent(pokemon: pokemon);
        },
      ),
    );
  }

  void _showFavorites(
    BuildContext context,
    PokemonController controller,
    List<Pokemon> pokemon,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final favorites = controller.favorites(pokemon);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: favorites.isEmpty
                ? const Text('No favorite Pokémon yet.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorites',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      ...favorites.map(
                        (item) => ListTile(
                          leading: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          title: Text(
                            controller.nicknames[item.id] ?? item.displayName,
                          ),
                          subtitle: Text(item.types.join(' / ')),
                          trailing: IconButton(
                            tooltip: 'Remove from favorites',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              controller.toggleFavorite(item.id);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _PokemonContent extends ConsumerWidget {
  final List<Pokemon> pokemon;

  const _PokemonContent({required this.pokemon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(pokemonControllerProvider.notifier);
    final filtered = controller.filteredPokemon(pokemon);
    final types = controller.availableTypes(pokemon);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: controller.selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Filter by type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All types'),
                    ),
                    ...types.map(
                      (type) => DropdownMenuItem<String?>(
                        value: type,
                        child: Text(_capitalize(type)),
                      ),
                    ),
                  ],
                  onChanged: controller.setType,
                ),
              ),
              const SizedBox(width: 8),
              Text('${filtered.length}/${pokemon.length}'),
            ],
          ),
        ),
        if (filtered.isEmpty)
          const Expanded(
            child: Center(child: Text('No Pokémon match this type.')),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.67,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return PokemonCard(
                  pokemon: item,
                  isFavorite: controller.favoriteIds.contains(item.id),
                  nickname: controller.nicknames[item.id],
                  onFavorite: () => controller.toggleFavorite(item.id),
                  onEditNickname: () =>
                      _editNickname(context, controller, item),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _editNickname(
    BuildContext context,
    PokemonController controller,
    Pokemon pokemon,
  ) async {
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => _NicknameDialog(
        pokemonName: pokemon.displayName,
        initialNickname: controller.nicknames[pokemon.id],
      ),
    );
    if (nickname != null) controller.saveNickname(pokemon.id, nickname);
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _NicknameDialog extends StatefulWidget {
  final String pokemonName;
  final String? initialNickname;

  const _NicknameDialog({
    required this.pokemonName,
    required this.initialNickname,
  });

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialNickname ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nickname for ${widget.pokemonName}'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(hintText: 'Enter a nickname'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _textController.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
