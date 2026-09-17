import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const MyApp());

class Product {
  const Product({
    required this.name,
    required this.price,
    required this.images,
    required this.description,
  });
  final String name;
  final double price;
  final List<String> images;
  final String description;
}

const products = [
  Product(
    name: 'Emote Comission',
    price: 10.99,
    images: ['assets/images/ReniaBoom.png'],
    description: 'Emote for Discord, Twitch, etc.',
  ),
  Product(
    name: 'ZZZ-Style Mindscape Cinema Illustration',
    price: 99.99,
    images: ['assets/images/KumiCrop.png', 'assets/images/KumiFull.png'],
    description:
        "Art based on Zenless Zone Zero's Mindscape Cinema illustrations.",
  ),
  Product(
    name: 'BA-Style Character Preview',
    price: 159.99,
    images: ['assets/images/YuikaPortrait.png', 'assets/images/YuikaFull.png'],
    description:
        'Fully rendered full body art of your character of choice (OCS Included!) with 4 expressions.',
  ),
  Product(
    name: 'Full Body Illustration',
    price: 99.99,
    images: ['assets/images/Urara.png', 'assets/images/UraraFull.png'],
    description: 'A full-body illustration of your character.',
  ),
];

class CartModel extends ChangeNotifier {
  final Map<Product, int> _items = {};
  Map<Product, int> get items => Map.unmodifiable(_items);
  int get itemCount =>
      _items.values.fold(0, (total, quantity) => total + quantity);
  double get total => _items.entries.fold(
    0,
    (sum, entry) => sum + entry.key.price * entry.value,
  );

  void add(Product product) {
    _items[product] = (_items[product] ?? 0) + 1;
    notifyListeners();
  }

  void decrease(Product product) {
    if ((_items[product] ?? 0) <= 1) {
      _items.remove(product);
    } else {
      _items[product] = _items[product]! - 1;
    }
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final cart = CartModel();
  bool isDark = false;

  late final GoRouter router = GoRouter(
    redirect: (context, state) =>
        (state.uri.path == '/checkout' ||
                state.uri.path == '/order-confirmed') &&
            cart.itemCount == 0
        ? '/cart'
        : null,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomePage(
          cart: cart,
          onToggleTheme: () => setState(() => isDark = !isDark),
        ),
      ),
      GoRoute(
        path: '/product/:index',
        builder: (context, state) {
          final index = int.parse(state.pathParameters['index']!);
          return DetailsPage(product: products[index], cart: cart);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => CartPage(cart: cart),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => CheckoutPage(cart: cart),
      ),
      GoRoute(
        path: '/order-confirmed',
        builder: (context, state) => OrderConfirmedPage(cart: cart),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 250, 33, 199),
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    return MaterialApp.router(
      title: "Reniacc's Comission Services",
      routerConfig: router,
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
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.cart, required this.onToggleTheme, super.key});
  final CartModel cart;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Reniacc's Comission Services"),
      actions: [
        IconButton(
          onPressed: onToggleTheme,
          icon: const Icon(Icons.brightness_6_outlined),
          tooltip: 'Toggle theme',
        ),
        CartButton(cart: cart),
      ],
    ),
    body: LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //Displays 3 items at once if the screen is wide enough, otherwise 2 items
          crossAxisCount: constraints.maxWidth >= 800 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: .72,
        ),
        itemBuilder: (context, index) => ProductCard(
          product: products[index],
          onTap: () => context.go('/product/$index'),
        ),
      ),
    ),
  );
}

//Build product cards
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onTap, super.key});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(product.images.first, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            Text(product.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text('VIEW DETAILS'),
                Spacer(),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class CartButton extends StatelessWidget {
  const CartButton({required this.cart, super.key});
  final CartModel cart;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: cart,
    builder: (context, child) => IconButton(
      onPressed: () => context.go('/cart'),
      icon: Badge(
        label: Text('${cart.itemCount}'),
        isLabelVisible: cart.itemCount > 0,
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      tooltip: 'Open cart',
    ),
  );
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({required this.product, required this.cart, super.key});
  final Product product;
  final CartModel cart;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DETAILS')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          product.images.length > 1
                              ? product.images[1]
                              : product.images.first,
                          height: 280,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              'From \$${product.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              product.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  cart.add(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('ADD TO CART'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CartPage extends StatelessWidget {
  const CartPage({required this.cart, super.key});
  final CartModel cart;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('YOUR CART')),
    body: AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        if (cart.items.isEmpty) {
          return const Center(child: Text('Your cart is empty'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...cart.items.entries.map(
              (entry) => Card(
                child: ListTile(
                  leading: Image.asset(entry.key.images.first, width: 56),
                  title: Text(entry.key.name),
                  subtitle: Text(
                    '\$${entry.key.price.toStringAsFixed(2)} each',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => cart.decrease(entry.key),
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${entry.value}'),
                      IconButton(
                        onPressed: () => cart.add(entry.key),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Subtotal  \$${cart.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/checkout'),
              child: const Text('REVIEW ORDER'),
            ),
          ],
        );
      },
    ),
  );
}

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({required this.cart, super.key});
  final CartModel cart;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('CONFIRM PURCHASE')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Review your order',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...cart.items.entries.map(
          (entry) => Card(
            child: ListTile(
              leading: Image.asset(entry.key.images.first, width: 56),
              title: Text(entry.key.name),
              subtitle: Text('${entry.value} item(s)'),
              trailing: Text(
                '\$${(entry.key.price * entry.value).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Total  \$${cart.total.toStringAsFixed(2)}',
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.go('/order-confirmed'),
          icon: const Icon(Icons.check),
          label: const Text('CONFIRM PURCHASE'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.go('/cart'),
          child: const Text('BACK TO CART'),
        ),
      ],
    ),
  );
}

class OrderConfirmedPage extends StatelessWidget {
  const OrderConfirmedPage({required this.cart, super.key});
  final CartModel cart;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ORDER CONFIRMED')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Thanks for your order!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '${cart.itemCount} item(s)  -  Total \$${cart.total.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: const Text('CONTINUE SHOPPING'),
            ),
          ],
        ),
      ),
    ),
  );
}
