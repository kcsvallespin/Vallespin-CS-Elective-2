import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/items_screen.dart';

const supabaseUrl = 'https://sbdptpmrtoztuovpjheq.supabase.co';

// Pass the publishable (anon) key at run time so it isn't committed:
//   flutter run --dart-define=SUPABASE_ANON_KEY=your-publishable-key
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_ANON_KEY is missing. Run with '
      '--dart-define=SUPABASE_ANON_KEY=your-publishable-key',
    );
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  // ProviderScope enables Riverpod state management.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Items',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ItemsScreen(),
    );
  }
}
