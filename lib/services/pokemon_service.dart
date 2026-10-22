import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  final http.Client _client;

  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  void dispose() => _client.close();

  /// Fetches the first [limit] (30) Pokemon.
  ///
  /// Returns a Future instead of a Stream because this is a single
  /// request/response: we ask once and get one result (or one error).
  /// A Stream fits data that keeps arriving over time, such as live updates
  /// or a websocket. The list does not change while the app is open.
  Future<List<Pokemon>> fetchPokemon({int limit = 30}) async {
    final uri = Uri.parse('$_baseUrl?limit=$limit');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;

    final pokemon = results
        .map((json) => Pokemon.fromJson(json as Map<String, dynamic>))
        .toList();

    // The list endpoint does not include types, so enrich cards with the
    // detail endpoint while retaining the list if an individual detail fails.
    return Future.wait(
      pokemon.map((item) async {
        try {
          final detailResponse = await _client
              .get(Uri.parse('$_baseUrl/${item.id}'))
              .timeout(const Duration(seconds: 15));
          if (detailResponse.statusCode != 200) return item;
          final detail =
              jsonDecode(detailResponse.body) as Map<String, dynamic>;
          final types = (detail['types'] as List<dynamic>)
              .map(
                (entry) =>
                    ((entry as Map<String, dynamic>)['type']
                            as Map<String, dynamic>)['name']
                        as String,
              )
              .toList();
          return Pokemon(
            id: item.id,
            name: item.name,
            imageUrl: item.imageUrl,
            types: types.isEmpty ? const ['unknown'] : types,
          );
        } catch (_) {
          return item;
        }
      }),
    );
  }
}
