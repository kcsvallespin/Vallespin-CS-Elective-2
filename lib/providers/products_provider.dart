import 'dart:math' as math;

import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../models/product.dart';
import '../services/product_service.dart';
import 'auth_provider.dart';

final productServiceProvider =
    Provider<ProductService>((ref) => ProductService());

/// The product list: current page, filters (search, category, price) and
/// loading/saving/error flags. Screens read this state and call the
/// controller's methods; only [ProductService] talks to Supabase.
final productsControllerProvider =
    NotifierProvider<ProductsController, ProductsState>(
  ProductsController.new,
);

class ProductsState {
  static const pageSize = 8;

  final List<Product> products;

  /// Zero-based current page.
  final int page;

  /// Number of products matching the filters, across all pages.
  final int totalCount;

  /// Upper bound for the price slider (0 when there are no products).
  final double maxPrice;

  /// Selected price range, or null for any price.
  final RangeValues? priceFilter;
  final String search;
  final int? categoryId;

  final bool loading;
  final bool saving;
  final Object? error;

  const ProductsState({
    this.products = const [],
    this.page = 0,
    this.totalCount = 0,
    this.maxPrice = 0,
    this.priceFilter,
    this.search = '',
    this.categoryId,
    this.loading = false,
    this.saving = false,
    this.error,
  });

  int get pageCount => math.max(1, (totalCount / pageSize).ceil());
  bool get hasPrevious => page > 0;
  bool get hasNext => page < pageCount - 1;
  bool get hasFilters =>
      priceFilter != null || search.isNotEmpty || categoryId != null;

  ProductsState copyWith({
    List<Product>? products,
    int? page,
    int? totalCount,
    double? maxPrice,
    RangeValues? Function()? priceFilter,
    String? search,
    int? Function()? categoryId,
    bool? loading,
    bool? saving,
    Object? Function()? error,
  }) {
    return ProductsState(
      products: products ?? this.products,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      maxPrice: maxPrice ?? this.maxPrice,
      priceFilter: priceFilter != null ? priceFilter() : this.priceFilter,
      search: search ?? this.search,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: error != null ? error() : this.error,
    );
  }
}

class ProductsController extends Notifier<ProductsState> {
  /// Incremented per request so slow, outdated responses are ignored.
  int _requestId = 0;

  ProductService get _service => ref.read(productServiceProvider);

  @override
  ProductsState build() {
    // Start fresh whenever a different user signs in or out.
    final userId = ref.watch(currentUserIdProvider);
    _requestId++;
    if (userId == null) return const ProductsState();
    Future.microtask(refresh);
    return const ProductsState(loading: true);
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

  Future<void> setSearch(String search) async {
    final term = search.trim();
    if (term == state.search) return;
    state = state.copyWith(search: term);
    await _loadPage(0);
  }

  Future<void> setCategory(int? categoryId) async {
    if (categoryId == state.categoryId) return;
    state = state.copyWith(categoryId: () => categoryId);
    await _loadPage(0);
  }

  /// Applies a price range; selecting the full range clears the filter.
  Future<void> setPriceFilter(RangeValues? range) async {
    final isFullRange =
        range != null && range.start <= 0 && range.end >= state.maxPrice;
    state = state.copyWith(priceFilter: () => isFullRange ? null : range);
    await _loadPage(0);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      search: '',
      categoryId: () => null,
      priceFilter: () => null,
    );
    await _loadPage(0);
  }

  /// New products are newest, so they appear on the first page.
  Future<void> create(ProductInput input) =>
      _mutate(() => _service.create(input), reloadPage: 0);

  Future<void> update(Product product, ProductInput input) =>
      _mutate(() => _service.update(product, input), reloadPage: state.page);

  Future<void> delete(Product product) {
    // If this was the last product on the last page, step back a page.
    final remaining = math.max(0, state.totalCount - 1);
    final lastPage =
        math.max(0, (remaining / ProductsState.pageSize).ceil() - 1);
    return _mutate(
      () => _service.delete(product),
      reloadPage: math.min(state.page, lastPage),
    );
  }

  /// Runs a create/update/delete, then reloads. Errors are rethrown so the
  /// screen can show them.
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
      // Round the slider's top up to a whole 10 so it looks tidy.
      final bound = max == null || max <= 0 ? 0.0 : (max / 10).ceil() * 10.0;
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
        pageSize: ProductsState.pageSize,
        search: state.search,
        categoryId: state.categoryId,
        minPrice: filter?.start,
        maxPrice: filter?.end,
      );
      if (id != _requestId) return;
      state = state.copyWith(
        products: result.products,
        page: page,
        totalCount: result.totalCount,
        loading: false,
      );
    } on PostgrestException catch (e) {
      if (id != _requestId) return;
      // PGRST103: requested range is past the end (rows changed elsewhere).
      if (e.code == 'PGRST103' && page > 0) return _loadPage(0);
      state = state.copyWith(loading: false, error: () => e);
    } catch (e) {
      if (id != _requestId) return;
      state = state.copyWith(loading: false, error: () => e);
    }
  }
}
