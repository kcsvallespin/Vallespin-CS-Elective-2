import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'apple.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const FruitsPage()),
    GoRoute(
      path: '/fruit/:name',
      builder: (context, state) {
        final name = state.pathParameters['name'] ?? 'apple';
        return ApplePage(name: name);
      },
    ),
  ],
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fluttering',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 183, 58, 58),
        ),
      ),
    );
  }
}

class FruitsPage extends StatelessWidget {
  const FruitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fruits')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.go('/fruit/apple'),
              child: const Text('Apple'),
            ),
            TextButton(
              onPressed: () => context.go('/fruit/orange'),
              child: const Text('Orange'),
            ),
            //const Text('Banana'),
            //const Text('Orange'),
          ],
        ),
      ),
    );
  }
}
