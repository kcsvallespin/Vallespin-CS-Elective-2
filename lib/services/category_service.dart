import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_category.dart';

/// CRUD for the `categories` table. Writes are allowed by RLS for admins only.
class CategoryService {
  CategoryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  static const _table = 'categories';

  final SupabaseClient _client;

  Future<List<ProductCategory>> fetchAll() async {
    final rows = await _client.from(_table).select('id, name').order('name');
    return rows.map(ProductCategory.fromJson).toList();
  }

  Future<ProductCategory> create(String name) async {
    final row = await _client
        .from(_table)
        .insert({'name': name.trim()})
        .select('id, name')
        .single();
    return ProductCategory.fromJson(row);
  }

  Future<ProductCategory> update(int id, String name) async {
    final row = await _client
        .from(_table)
        .update({'name': name.trim()})
        .eq('id', id)
        .select('id, name')
        .single();
    return ProductCategory.fromJson(row);
  }

  Future<void> delete(int id) async {
    final deleted =
        await _client.from(_table).delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      // RLS silently filters out rows the user may not delete.
      throw const PostgrestException(
        message: "You don't have permission to delete this category.",
        code: '42501',
      );
    }
  }
}
