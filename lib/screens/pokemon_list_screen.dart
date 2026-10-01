import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/status_message.dart';

class PokemonListScreen extends StatefulWidget {
  final PokemonService? service;

  const PokemonListScreen({super.key, this.service});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  late final PokemonService _service;
  late Future<List<Pokemon>> _pokemonFuture;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PokemonService();
    // Start the request here, not in build(). build() can run many times,
    // and starting it there would re-fetch on every rebuild.
    _pokemonFuture = _service.fetchPokemon(limit: 30);
  }

  void _retry() {
    setState(() {
      _pokemonFuture = _service.fetchPokemon(limit: 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Pokemon>>(
        future: _pokemonFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return StatusMessage(
              icon: Icons.wifi_off,
              message:
                  'Something went wrong while loading Pokémon.\n${snapshot.error}',
              actionLabel: 'Retry',
              onAction: _retry,
            );
          }

          // Empty state
          final pokemon = snapshot.data ?? [];
          if (pokemon.isEmpty) {
            return StatusMessage(
              icon: Icons.catching_pokemon,
              message: 'No Pokémon found.',
              actionLabel: 'Reload',
              onAction: _retry,
            );
          }

          // Success state: scrollable grid
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: pokemon.length,
            itemBuilder: (context, index) =>
                PokemonCard(pokemon: pokemon[index]),
          );
        },
      ),
    );
  }
}
