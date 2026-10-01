import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_flutter_project/screens/pokemon_list_screen.dart';
import 'package:my_flutter_project/services/pokemon_service.dart';

Widget _app(http.Client client) => MaterialApp(
      home: PokemonListScreen(service: PokemonService(client: client)),
    );

void main() {
  testWidgets('shows Pokemon names and IDs in a grid', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['limit'], '30');
      return http.Response(
        jsonEncode({
          'results': [
            {'name': 'bulbasaur', 'url': 'https://pokeapi.co/api/v2/pokemon/1/'},
            {'name': 'ivysaur', 'url': 'https://pokeapi.co/api/v2/pokemon/2/'},
          ],
        }),
        200,
      );
    });

    await tester.pumpWidget(_app(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('#002'), findsOneWidget);
  });

  testWidgets('shows error state with retry on failure', (tester) async {
    final client = MockClient((_) async => http.Response('oops', 500));

    await tester.pumpWidget(_app(client));
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows empty state when no results', (tester) async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'results': []}), 200),
    );

    await tester.pumpWidget(_app(client));
    await tester.pump();
    expect(find.text('No Pokémon found.'), findsOneWidget);
  });
}
