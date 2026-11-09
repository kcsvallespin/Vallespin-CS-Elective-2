import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/theme_provider.dart';
import 'screens/shop_screen.dart';

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
      home: const ShopScreen(),
    );
  }
}
