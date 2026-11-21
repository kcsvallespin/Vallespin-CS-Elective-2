import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_category.dart';
import '../services/category_service.dart';
import 'auth_provider.dart';
import 'products_provider.dart';

final categoryServiceProvider =
    Provider<CategoryService>((ref) => CategoryService());

/// All categories, sorted by name. Used for the customer filter chips, the
/// product form's dropdown and the admin category screen.
final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<ProductCategory>>(
  CategoriesController.new,
);

class CategoriesController extends AsyncNotifier<List<ProductCategory>> {
  CategoryService get _service => ref.read(categoryServiceProvider);

  @override
  Future<List<ProductCategory>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    return ref.read(categoryServiceProvider).fetchAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<ProductCategory>>()
        .copyWithPrevious(state);
    state = await AsyncValue.guard(_service.fetchAll);
  }

  /// Errors are rethrown so the screen can show them.
  Future<void> create(String name) async {
    final created = await _service.create(name);
    _set([...?state.valueOrNull, created]);
  }

  Future<void> rename(ProductCategory category, String name) async {
    final updated = await _service.update(category.id, name);
    _set([
      for (final c in state.valueOrNull ?? const <ProductCategory>[])
        c.id == updated.id ? updated : c,
    ]);
    // Product cards show the category name, so reload them.
    await ref.read(productsControllerProvider.notifier).refresh();
  }

  Future<void> delete(ProductCategory category) async {
    await _service.delete(category.id);
    _set([
      for (final c in state.valueOrNull ?? const <ProductCategory>[])
        if (c.id != category.id) c,
    ]);
    final products = ref.read(productsControllerProvider.notifier);
    if (ref.read(productsControllerProvider).categoryId == category.id) {
      await products.setCategory(null);
    }
  }

  void _set(List<ProductCategory> list) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    state = AsyncData(list);
  }
}
