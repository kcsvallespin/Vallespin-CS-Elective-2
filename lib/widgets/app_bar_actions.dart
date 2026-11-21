import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/customer/cart_screen.dart';
import '../utils/errors.dart';
import 'status_message.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(darkModeProvider);
    return IconButton(
      onPressed: () => ref.read(darkModeProvider.notifier).toggle(),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: dark ? 'Light mode' : 'Dark mode',
    );
  }
}

/// Signs out after confirming. The cart is emptied automatically because it
/// is tied to the signed-in user.
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your cart will be emptied.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(authControllerProvider.notifier).signOut();
    if (!ok && context.mounted) {
      final error = ref.read(authControllerProvider).error;
      showSnack(context, errorMessage(error ?? 'Sign out failed.'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _signOut(context, ref),
      icon: const Icon(Icons.logout),
      tooltip: 'Sign out',
    );
  }
}

/// Cart icon with a badge showing how many items are in the cart.
class CartButton extends ConsumerWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartControllerProvider).itemCount;
    return IconButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      tooltip: 'Cart',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

/// "Add to cart" button that respects stock and shows what happened.
class AddToCartButton extends ConsumerWidget {
  const AddToCartButton({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = ref.watch(
      cartControllerProvider.select((c) => c.quantityOf(product.id)),
    );
    final atLimit = inCart >= product.stock;

    if (!product.inStock) {
      return const SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: null, child: Text('Out of stock')),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: atLimit
            ? null
            : () {
                final result =
                    ref.read(cartControllerProvider.notifier).add(product);
                showSnack(context, switch (result) {
                  AddToCartResult.added => 'Added ${product.name} to cart',
                  AddToCartResult.outOfStock =>
                    '${product.name} is out of stock',
                  AddToCartResult.stockLimitReached =>
                    'Only ${product.stock} in stock',
                });
              },
        icon: const Icon(Icons.add_shopping_cart, size: 18),
        label: Text(
          atLimit
              ? 'Max in cart'
              : inCart > 0
                  ? 'Add more ($inCart)'
                  : 'Add to cart',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
