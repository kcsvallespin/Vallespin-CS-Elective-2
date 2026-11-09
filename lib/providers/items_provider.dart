import 'dart:math' as math;

import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../models/item.dart';
import '../services/item_service.dart';

final itemServiceProvider = Provider<ItemService>((ref) => ItemService());

/// Holds the shop's list state: the current page of items, pagination info,
/// the price filter, and loading/saving/error flags. The screen only reads
/// this state and calls the controller's methods; all Supabase calls go
/// through the controller.
final itemsControllerProvider =
    NotifierProvider<ItemsController, ItemsState>(ItemsController.new);

class ItemsState {
  static const pageSize = 6;

  /// Items on the current page (at most [pageSize]).
  final List<Item> items;

  /// Zero-based current page.
  final int page;

  /// Number of items matching the current filter, across all pages.
  final int totalCount;

  /// Upper bound for the price slider (0 when no item has a price).
  final double maxPrice;

  /// Selected price range, or null for "all items" (including unpriced ones).
  final RangeValues? priceFilter;

  final bool loading;
  final bool saving;
  final Object? error;

  const ItemsState({
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.maxPrice = 0,
    this.priceFilter,
    this.loading = false,
    this.saving = false,
    this.error,
  });

  int get pageCount => math.max(1, (totalCount / pageSize).ceil());
  bool get hasPrevious => page > 0;
  bool get hasNext => page < pageCount - 1;

  ItemsState copyWith({
    List<Item>? items,
    int? page,
    int? totalCount,
    double? maxPrice,
    RangeValues? Function()? priceFilter,
    bool? loading,
    bool? saving,
    Object? Function()? error,
  }) {
    return ItemsState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      maxPrice: maxPrice ?? this.maxPrice,
      priceFilter: priceFilter != null ? priceFilter() : this.priceFilter,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: error != null ? error() : this.error,
    );
  }
}

class ItemsController extends Notifier<ItemsState> {
  /// Incremented per page request so slow, outdated responses are ignored
  /// (e.g. when the user drags the slider twice quickly).
  int _requestId = 0;

  ItemService get _service => ref.read(itemServiceProvider);

  @override
  ItemsState build() {
    Future.microtask(refresh);
    return const ItemsState(loading: true);
  }

  /// Reloads the slider bounds and the current page.
  Future<void> refresh() async {
    await _loadPriceBounds();
    await _loadPage(state.page);
  }

  Future<void> goToPage(int page) async {
    if (page < 0 || page >= state.pageCount || page == state.page) return;
    await _loadPage(page);
  }

  /// Applies a price range and jumps back to the first page. Selecting the
  /// full range clears the filter so unpriced items show again.
  Future<void> setPriceFilter(RangeValues? range) async {
    final isFullRange = range != null &&
        range.start <= 0 &&
        range.end >= state.maxPrice;
    state = state.copyWith(
      priceFilter: () => isFullRange ? null : range,
    );
    await _loadPage(0);
  }

  Future<void> createItem({
    required String name,
    String? description,
    String? imageUrl,
    double? price,
    PickedImage? image,
  }) {
    // New items are newest, so they appear on page 1.
    return _mutate(
      () => _service.createItem(
        name: name,
        description: description,
        imageUrl: imageUrl,
        price: price,
        image: image,
      ),
      reloadPage: 0,
    );
  }

  Future<void> updateItem(
    Item item, {
    required String name,
    String? description,
    String? imageUrl,
    double? price,
    PickedImage? image,
  }) {
    return _mutate(
      () => _service.updateItem(
        item,
        name: name,
        description: description,
        imageUrl: imageUrl,
        price: price,
        image: image,
      ),
      reloadPage: state.page,
    );
  }

  Future<void> deleteItem(Item item) {
    // If this was the last item on the last page, step back a page.
    final remaining = math.max(0, state.totalCount - 1);
    final lastPage = math.max(0, (remaining / ItemsState.pageSize).ceil() - 1);
    return _mutate(
      () => _service.deleteItem(item),
      reloadPage: math.min(state.page, lastPage),
    );
  }

  /// Runs a create/update/delete, then refreshes bounds and the page.
  /// Errors are rethrown so the screen can show them.
  Future<void> _mutate(
    Future<void> Function() action, {
    required int reloadPage,
  }) async {
    state = state.copyWith(saving: true);
    try {
      await action();
      await _loadPriceBounds();
      await _loadPage(reloadPage);
    } finally {
      state = state.copyWith(saving: false);
    }
  }

  Future<void> _loadPriceBounds() async {
    try {
      final max = await _service.fetchMaxPrice();
      // Round the slider's top up to a whole $10 so it looks tidy.
      final bound = max == null ? 0.0 : (max / 10).ceil() * 10.0;
      final filter = state.priceFilter;
      RangeValues? clamped;
      if (filter != null && bound > 0) {
        final end = math.min(filter.end, bound);
        clamped = RangeValues(math.min(filter.start, end), end);
      }
      state = state.copyWith(maxPrice: bound, priceFilter: () => clamped);
    } catch (_) {
      // Keep the old bounds; the page load will surface any real error.
    }
  }

  Future<void> _loadPage(int page) async {
    final id = ++_requestId;
    state = state.copyWith(loading: true, error: () => null);
    try {
      final filter = state.priceFilter;
      final result = await _service.fetchPage(
        page: page,
        pageSize: ItemsState.pageSize,
        minPrice: filter?.start,
        maxPrice: filter?.end,
      );
      if (id != _requestId) return;
      state = state.copyWith(
        items: result.items,
        page: page,
        totalCount: result.totalCount,
        loading: false,
      );
    } on PostgrestException catch (e) {
      if (id != _requestId) return;
      // PGRST103: requested range is past the end (rows changed elsewhere).
      if (e.code == 'PGRST103' && page > 0) return _loadPage(0);
      state = state.copyWith(loading: false, error: () => e.message);
    } catch (e) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: () => e);
    }
  }
}
