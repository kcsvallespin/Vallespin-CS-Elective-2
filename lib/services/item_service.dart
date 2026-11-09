import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item.dart';

/// A newly picked image that still needs to be uploaded.
class PickedImage {
  final Uint8List bytes;
  final String fileExt;

  const PickedImage(this.bytes, this.fileExt);
}

/// One page of results plus the total number of matching rows.
class ItemPage {
  final List<Item> items;
  final int totalCount;

  const ItemPage({required this.items, required this.totalCount});
}

/// CRUD operations for the Supabase `items` table, plus image storage in the
/// `item-images` bucket.
class ItemService {
  static const _table = 'items';
  static const _bucket = 'item-images';

  final SupabaseClient _client;

  ItemService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  /// Fetches one page of items, newest first, optionally filtered to a price
  /// range. Filtering and pagination both happen in the Supabase query:
  /// `gte`/`lte` on price, then `range(from, to)` for the page, with an exact
  /// row count so the UI knows how many pages there are.
  Future<ItemPage> fetchPage({
    required int page,
    required int pageSize,
    double? minPrice,
    double? maxPrice,
  }) async {
    var query = _client.from(_table).select();
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);

    final from = page * pageSize;
    final to = from + pageSize - 1;
    final response = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(from, to)
        .count(CountOption.exact);

    return ItemPage(
      items: response.data.map(Item.fromJson).toList(),
      totalCount: response.count,
    );
  }

  /// Highest price in the table, used as the slider's upper bound.
  /// Returns null when no item has a price.
  Future<double?> fetchMaxPrice() async {
    final row = await _client
        .from(_table)
        .select('price')
        .not('price', 'is', null)
        .order('price', ascending: false)
        .limit(1)
        .maybeSingle();
    return (row?['price'] as num?)?.toDouble();
  }

  /// Creates an item. If [image] is given it is uploaded first and its public
  /// URL is saved; otherwise [imageUrl] (e.g. a pasted link) is used.
  Future<Item> createItem({
    required String name,
    String? description,
    String? imageUrl,
    double? price,
    PickedImage? image,
  }) async {
    final uploadedUrl = image == null ? null : await uploadImage(image);
    try {
      final row = await _client
          .from(_table)
          .insert(_payload(name, description, uploadedUrl ?? imageUrl, price))
          .select()
          .single();
      return Item.fromJson(row);
    } catch (_) {
      // Don't leave an orphaned file if the insert fails.
      if (uploadedUrl != null) await deleteImageByUrl(uploadedUrl);
      rethrow;
    }
  }

  /// Updates an item. Uploads [image] if given, and removes the item's old
  /// image from storage when it was replaced or cleared.
  Future<Item> updateItem(
    Item existing, {
    required String name,
    String? description,
    String? imageUrl,
    double? price,
    PickedImage? image,
  }) async {
    final uploadedUrl = image == null ? null : await uploadImage(image);
    final Map<String, dynamic> row;
    try {
      row = await _client
          .from(_table)
          .update(_payload(name, description, uploadedUrl ?? imageUrl, price))
          .eq('id', existing.id)
          .select()
          .single();
    } catch (_) {
      if (uploadedUrl != null) await deleteImageByUrl(uploadedUrl);
      rethrow;
    }

    final updated = Item.fromJson(row);
    final oldUrl = existing.imageUrl;
    if (oldUrl != null && oldUrl != updated.imageUrl) {
      await deleteImageByUrl(oldUrl);
    }
    return updated;
  }

  /// Deletes an item and its uploaded image, if any.
  Future<void> deleteItem(Item item) async {
    await _client.from(_table).delete().eq('id', item.id);
    if (item.imageUrl != null) await deleteImageByUrl(item.imageUrl!);
  }

  /// Uploads [image] to the bucket and returns its public URL.
  Future<String> uploadImage(PickedImage image) async {
    final ext = image.fileExt.toLowerCase();
    final contentType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
    final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Removes a file from the bucket given its public URL. URLs that don't
  /// point at this bucket (e.g. pasted external links) are ignored, and
  /// cleanup failures never break the main operation.
  Future<void> deleteImageByUrl(String url) async {
    final path = _storagePath(url);
    if (path == null) return;
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // Best effort: an orphaned file is better than a failed save.
    }
  }

  String? _storagePath(String url) {
    const marker = '/storage/v1/object/public/$_bucket/';
    final i = url.indexOf(marker);
    if (i == -1) return null;
    return Uri.decodeComponent(url.substring(i + marker.length).split('?').first);
  }

  Map<String, dynamic> _payload(
    String name,
    String? description,
    String? imageUrl,
    double? price,
  ) {
    String? clean(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();
    return {
      'name': name.trim(),
      'description': clean(description),
      'image_url': clean(imageUrl),
      'price': price,
    };
  }
}
