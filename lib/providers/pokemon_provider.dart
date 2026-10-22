import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';

final pokemonServiceProvider = Provider<PokemonService>((ref) {
  final service = PokemonService();
  ref.onDispose(service.dispose);
  return service;
});

// The PokemonController is an AsyncNotifier that manages the state of a list of Pokemon.
// This provides: The Pokemon List, Loading State, Error State, Refreshing, Filtering,
// Favourites and Nicknames
final pokemonControllerProvider =
    AsyncNotifierProvider<PokemonController, List<Pokemon>>(
      PokemonController.new,
    );

class PokemonController extends AsyncNotifier<List<Pokemon>> {
  final Set<int> _favorites = <int>{};
  final Map<int, String> _nicknames = <int, String>{};
  String? _selectedType;

  String? get selectedType => _selectedType;
  Set<int> get favoriteIds => Set.unmodifiable(_favorites);
  Map<int, String> get nicknames => Map.unmodifiable(_nicknames);

  @override
  Future<List<Pokemon>> build() {
    return ref.read(pokemonServiceProvider).fetchPokemon(limit: 30);
  }

  List<Pokemon> filteredPokemon(List<Pokemon> pokemon) {
    if (_selectedType == null) return pokemon;
    return pokemon.where((item) => item.types.contains(_selectedType)).toList();
  }

  List<String> availableTypes(List<Pokemon> pokemon) {
    final types = pokemon.expand((item) => item.types).toSet().toList()..sort();
    return types;
  }

  List<Pokemon> favorites(List<Pokemon> pokemon) =>
      pokemon.where((item) => _favorites.contains(item.id)).toList();

  void setType(String? type) {
    _selectedType = type;
    _refresh();
  }

  void toggleFavorite(int id) {
    if (!_favorites.add(id)) _favorites.remove(id);
    _refresh();
  }

  void saveNickname(int id, String nickname) {
    final value = nickname.trim();
    if (value.isEmpty) {
      _nicknames.remove(id);
    } else {
      _nicknames[id] = value;
    }
    _refresh();
  }

  Future<void> retry() async {
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(pokemonServiceProvider).fetchPokemon(limit: 30),
    );
  }

  void _refresh() {
    final current = state.valueOrNull;
    if (current != null) state = AsyncData(List.unmodifiable(current));
  }
}
