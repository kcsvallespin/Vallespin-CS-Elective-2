import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/theme_provider.dart';
import 'screens/auth_gate.dart';

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
    final isDark = ref.watch(darkModeProvider);
    final colors = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 250, 33, 199),
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    return MaterialApp(
      title: "Reniacc's Comission Services",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colors,
        useMaterial3: true,
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
        appBarTheme: AppBarTheme(
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.primaryContainer,
          contentTextStyle: TextStyle(color: colors.onPrimaryContainer),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
