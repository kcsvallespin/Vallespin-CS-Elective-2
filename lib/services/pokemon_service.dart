import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  final http.Client _client;

  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the first [limit] Pokemon.
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

    return results
        .map((json) => Pokemon.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
