import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item.dart';
import '../providers/items_provider.dart';
import 'status_message.dart';

/// Shows loading / error / empty states for the current page, and calls
/// [builder] with the items once there is something to show.
class ItemsStateView extends ConsumerWidget {
  final Widget Function(BuildContext context, List<Item> items) builder;

  const ItemsStateView({super.key, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemsControllerProvider);
    final controller = ref.read(itemsControllerProvider.notifier);

    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return StatusMessage(
        icon: Icons.wifi_off,
        message: 'Something went wrong while loading items.\n${state.error}',
        actionLabel: 'Retry',
        onAction: controller.refresh,
      );
    }
    if (state.items.isEmpty) {
      return state.priceFilter != null
          ? StatusMessage(
              icon: Icons.filter_alt_off_outlined,
              message: 'No items in this price range.',
              actionLabel: 'Clear filter',
              onAction: () => controller.setPriceFilter(null),
            )
          : StatusMessage(
              icon: Icons.storefront_outlined,
              message: 'No items yet.',
              actionLabel: 'Reload',
              onAction: controller.refresh,
            );
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: builder(context, state.items),
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
    final state = ref.watch(itemsControllerProvider);
    final theme = Theme.of(context);
    final max = state.maxPrice;
    if (max <= 0) return const SizedBox.shrink();

    final applied = state.priceFilter ?? RangeValues(0, max);
    final values = _dragging ?? applied;
    final filtering = state.priceFilter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                      .read(itemsControllerProvider.notifier)
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
              ref.read(itemsControllerProvider.notifier).setPriceFilter(v);
            },
          ),
          if (filtering)
            Text(
              'Items without a price are hidden while filtering.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
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
    final state = ref.watch(itemsControllerProvider);
    final controller = ref.read(itemsControllerProvider.notifier);
    final theme = Theme.of(context);
    final busy = state.loading || state.saving;

    if (state.totalCount == 0) return const SizedBox.shrink();

    final first = state.page * ItemsState.pageSize + 1;
    final last = first + state.items.length - 1;

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
PreferredSizeWidget? busyIndicator(ItemsState state) {
  final busy = state.loading || state.saving;
  if (!busy || state.items.isEmpty) return null;
  return const PreferredSize(
    preferredSize: Size.fromHeight(4),
    child: LinearProgressIndicator(),
  );
}

/// Network image with a placeholder for missing or broken URLs.
class ItemImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ItemImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox(
      width: width,
      height: height,
      child: Icon(
        url == null ? Icons.image_outlined : Icons.broken_image_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
