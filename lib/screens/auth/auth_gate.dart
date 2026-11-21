import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/status_message.dart';
import '../admin/admin_products_screen.dart';
import '../customer/shop_screen.dart';
import 'login_screen.dart';

/// Picks the first screen from the session and the user's role:
/// signed out -> login, admin -> product management, customer -> shop.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  static const _loading = Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user.when(
      loading: () => _loading,
      error: (_, _) => const LoginScreen(),
      data: (user) {
        if (user == null) return const LoginScreen();
        final profile = ref.watch(profileProvider);
        return profile.when(
          loading: () => _loading,
          error: (e, _) => _ProfileProblem(
            child: StatusMessage.error(
              e,
              onRetry: () => ref.invalidate(profileProvider),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return _ProfileProblem(
                child: StatusMessage(
                  icon: Icons.person_off_outlined,
                  message: 'No profile was found for this account.\n'
                      'Make sure the sign-up trigger is installed in '
                      'Supabase, then try again.',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(profileProvider),
                ),
              );
            }
            return profile.isAdmin
                ? const AdminProductsScreen()
                : const ShopScreen();
          },
        );
      },
    );
  }
}

class _ProfileProblem extends StatelessWidget {
  const _ProfileProblem({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [SignOutButton()]),
      body: child,
    );
  }
}
