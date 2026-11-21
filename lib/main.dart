import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

const supabaseUrl = 'https://sbdptpmrtoztuovpjheq.supabase.co';

// Pass the publishable (anon) key at run time so it isn't committed:
//   flutter run --dart-define=SUPABASE_ANON_KEY=your-publishable-key
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseAnonKey.isEmpty) {
    // Show the problem on screen instead of a blank white page.
    runApp(const _StartupError(
      'SUPABASE_ANON_KEY is missing.\n\nRun with:\n'
      'flutter run -d chrome --web-port 3000 '
      '--dart-define=SUPABASE_ANON_KEY=your-publishable-key',
    ));
    return;
  }
  try {
    await Supabase.initialize(
        url: supabaseUrl, publishableKey: supabaseAnonKey);
  } catch (e) {
    runApp(_StartupError('Could not connect to Supabase:\n$e'));
    return;
  }
  // ProviderScope enables Riverpod state management.
  runApp(const ProviderScope(child: MyApp()));
}

class _StartupError extends StatelessWidget {
  const _StartupError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When the user signs in, out, or switches accounts, drop any screens
    // left over from the previous session (cart, forms, ...) so the
    // AuthGate's screen for the new role is shown.
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next) {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    final isDark = ref.watch(darkModeProvider);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: "Reniacc's Commission Services",
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(isDark ? Brightness.dark : Brightness.light),
      home: const AuthGate(),
    );
  }
}
