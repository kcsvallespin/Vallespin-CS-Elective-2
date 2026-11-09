import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'responsive_screen.dart';
import 'adaptive_screen.dart';
import 'screens/items_screen.dart';

const supabaseUrl = 'https://sbdptpmrtoztuovpjheq.supabase.co';

// Pass the anon key at run time so it isn't committed:
//   flutter run --dart-define=SUPABASE_ANON_KEY=your-anon-key
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_ANON_KEY is missing. Run with '
      '--dart-define=SUPABASE_ANON_KEY=your-anon-key',
    );
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigator Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //const Text('This is the first screen'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailsScreen(),
                  ),
                );
              },
              child: const Text('Open Details'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdaptiveScreen(),
                  ),
                );
              },
              child: const Text('Open Adaptive Screen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ItemsScreen(),
                  ),
                );
              },
              child: const Text('Open Items'),
            ),
          ],
        ),
      ),
    );
  }
}
