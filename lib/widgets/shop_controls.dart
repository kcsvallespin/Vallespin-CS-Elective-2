import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/categories_provider.dart';
import '../providers/products_provider.dart';
import '../utils/format.dart';
import 'status_message.dart';

/// Shows loading / error / empty states for the product list, and calls
/// [builder] with the products once there is something to show.
class ProductsStateView extends ConsumerWidget {
  final Widget Function(BuildContext context, List<Product> products) builder;
  final String emptyMessage;

  const ProductsStateView({
    super.key,
    required this.builder,
    this.emptyMessage = 'No products yet.',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsControllerProvider);
    final controller = ref.read(productsControllerProvider.notifier);

    if (state.loading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.products.isEmpty) {
      return StatusMessage.error(state.error!, onRetry: controller.refresh);
    }
    if (state.products.isEmpty) {
      return state.hasFilters
          ? StatusMessage(
              icon: Icons.filter_alt_off_outlined,
              message: 'No products match your search or filters.',
              actionLabel: 'Clear filters',
              actionIcon: Icons.clear_all,
              onAction: controller.clearFilters,
            )
          : StatusMessage(
              icon: Icons.storefront_outlined,
              message: emptyMessage,
              actionLabel: 'Reload',
              onAction: controller.refresh,
            );
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: builder(context, state.products),
    );
  }
}

/// Responsive product grid: 2 columns on phones, more on wider screens.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    required this.products,
    required this.itemBuilder,
    super.key,
  });

  final List<Product> products;
  final Widget Function(BuildContext context, Product product) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1200
            ? 4
            : width >= 800
                ? 3
                : 2;
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 300,
          ),
          itemBuilder: (context, i) => itemBuilder(context, products[i]),
        );
      },
    );
  }
}

/// Search box plus category chips. Typing is debounced so we don't query
/// Supabase on every keystroke.
class SearchAndCategoryBar extends ConsumerStatefulWidget {
  const SearchAndCategoryBar({super.key});

  @override
  ConsumerState<SearchAndCategoryBar> createState() =>
      _SearchAndCategoryBarState();
}

class _SearchAndCategoryBarState extends ConsumerState<SearchAndCategoryBar> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(productsControllerProvider).search,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // show/hide the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(productsControllerProvider.notifier).setSearch(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _search.clear();
    setState(() {});
    ref.read(productsControllerProvider.notifier).setSearch('');
  }

  @override
  Widget build(BuildContext context) {
    // Keep the text box in sync when filters are cleared elsewhere.
    ref.listen(productsControllerProvider.select((s) => s.search), (_, next) {
      if (next.isEmpty && _search.text.trim().isNotEmpty) {
        _debounce?.cancel();
        _search.clear();
      }
    });

    final selected = ref.watch(
      productsControllerProvider.select((s) => s.categoryId),
    );
    final categories = ref.watch(categoriesControllerProvider);
    final controller = ref.read(productsControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _clear,
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: categories.when(
              loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Row(
                children: [
                  const Expanded(child: Text('Could not load categories.')),
                  TextButton(
                    onPressed: () => ref
                        .read(categoriesControllerProvider.notifier)
                        .refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (list) => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selected == null,
                    onSelected: (_) => controller.setCategory(null),
                  ),
                  for (final c in list) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(c.name),
                      selected: selected == c.id,
                      onSelected: (on) =>
                          controller.setCategory(on ? c.id : null),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Price range slider. Dragging only updates the labels; the Supabase query
/// runs when the user lets go, so we don't send a request per pixel.
class PriceFilterBar extends ConsumerStatefulWidget {
  const PriceFilterBar({super.key});

  @override
  ConsumerState<PriceFilterBar> createState() => _PriceFilterBarState();
}

class _PriceFilterBarState extends ConsumerState<PriceFilterBar> {
  RangeValues? _dragging;

  String _money(double v) => '$currencySymbol${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsControllerProvider);
    final theme = Theme.of(context);
    final max = state.maxPrice;
    if (max <= 0) return const SizedBox.shrink();

    final applied = state.priceFilter ?? RangeValues(0, max);
    final values = _dragging ?? applied;
    final filtering = state.priceFilter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('PRICE', style: theme.textTheme.labelLarge),
              const SizedBox(width: 12),
              Text(
                '${_money(values.start)} – ${_money(values.end)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (filtering)
                TextButton(
                  onPressed: () => ref
                      .read(productsControllerProvider.notifier)
                      .setPriceFilter(null),
                  child: const Text('CLEAR'),
                ),
            ],
          ),
          RangeSlider(
            min: 0,
            max: max,
            divisions: max.round().clamp(1, 1000),
            values: RangeValues(
              values.start.clamp(0, max),
              values.end.clamp(0, max),
            ),
            labels: RangeLabels(_money(values.start), _money(values.end)),
            onChanged: (v) => setState(() => _dragging = v),
            onChangeEnd: (v) {
              setState(() => _dragging = null);
              ref.read(productsControllerProvider.notifier).setPriceFilter(v);
            },
          ),
        ],
      ),
    );
  }
}

/// Previous / next controls with "Page X of Y".
class PaginationBar extends ConsumerWidget {
  const PaginationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsControllerProvider);
    final controller = ref.read(productsControllerProvider.notifier);
    final theme = Theme.of(context);
    final busy = state.loading || state.saving;

    if (state.totalCount == 0) return const SizedBox.shrink();

    final first = state.page * ProductsState.pageSize + 1;
    final last = first + state.products.length - 1;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
                onPressed: state.hasPrevious && !busy
                    ? () => controller.goToPage(state.page - 1)
                    : null,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page ${state.page + 1} of ${state.pageCount}',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      'Showing $first–$last of ${state.totalCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
                onPressed: state.hasNext && !busy
                    ? () => controller.goToPage(state.page + 1)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin progress bar under the app bar while a page loads or a save runs.
PreferredSizeWidget? busyIndicator(ProductsState state) {
  final busy = state.loading || state.saving;
  if (!busy || state.products.isEmpty) return null;
  return const PreferredSize(
    preferredSize: Size.fromHeight(4),
    child: LinearProgressIndicator(),
  );
}
