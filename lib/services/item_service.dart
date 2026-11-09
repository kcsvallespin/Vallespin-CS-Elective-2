import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item.dart';

/// CRUD operations for the Supabase `items` table.
class ItemService {
  static const _table = 'items';

  final SupabaseClient _client;

  ItemService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Item>> fetchItems() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return rows.map(Item.fromJson).toList();
  }

  Future<Item> createItem({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final row = await _client
        .from(_table)
        .insert(_payload(name, description, imageUrl))
        .select()
        .single();
    return Item.fromJson(row);
  }

  Future<Item> updateItem(
    int id, {
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final row = await _client
        .from(_table)
        .update(_payload(name, description, imageUrl))
        .eq('id', id)
        .select()
        .single();
    return Item.fromJson(row);
  }

  Future<void> deleteItem(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Map<String, dynamic> _payload(
    String name,
    String? description,
    String? imageUrl,
  ) {
    String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    return {
      'name': name.trim(),
      'description': clean(description),
      'image_url': clean(imageUrl),
    };
  }
}
