import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

/// A newly picked image that still needs to be uploaded.
class PickedImage {
  final Uint8List bytes;
  final String fileExt;

  const PickedImage(this.bytes, this.fileExt);
}

/// Values from the admin product form.
class ProductInput {
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int categoryId;

  /// Image URL to keep or save when no new file was picked (empty clears it).
  final String? imageUrl;

  /// Newly picked file to upload. Takes priority over [imageUrl].
  final PickedImage? image;

  const ProductInput({
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imageUrl,
    this.image,
  });
}

/// One page of results plus the total number of matching rows.
class ProductPage {
  final List<Product> products;
  final int totalCount;

  const ProductPage({required this.products, required this.totalCount});
}

/// Reads and writes the `products` table and product images in Supabase
/// Storage. Writes are allowed by RLS for admins only.
class ProductService {
  ProductService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  static const _table = 'products';
  static const _bucket = 'item-images';
  static const _select = '*, categories(name)';

  final SupabaseClient _client;

  /// Fetches one page of products, newest first. Search, category and price
  /// filters and pagination all run in the Supabase query.
  Future<ProductPage> fetchPage({
    required int page,
    required int pageSize,
    String search = '',
    int? categoryId,
    double? minPrice,
    double? maxPrice,
  }) async {
    var query = _client.from(_table).select(_select);
    final term = search.trim();
    if (term.isNotEmpty) query = query.ilike('name', '%${_escapeLike(term)}%');
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);

    final from = page * pageSize;
    final response = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(from, from + pageSize - 1)
        .count(CountOption.exact);

    return ProductPage(
      products: response.data.map(Product.fromJson).toList(),
      totalCount: response.count,
    );
  }

  /// Highest product price, used as the price slider's upper bound.
  Future<double?> fetchMaxPrice() async {
    final row = await _client
        .from(_table)
        .select('price')
        .order('price', ascending: false)
        .limit(1)
        .maybeSingle();
    return (row?['price'] as num?)?.toDouble();
  }

  Future<Product> create(ProductInput input) async {
    final uploadedUrl =
        input.image == null ? null : await uploadImage(input.image!);
    try {
      final row = await _client
          .from(_table)
          .insert(_payload(input, uploadedUrl))
          .select(_select)
          .single();
      return Product.fromJson(row);
    } catch (_) {
      // Don't leave an orphaned file if the insert fails.
      if (uploadedUrl != null) await deleteImageByUrl(uploadedUrl);
      rethrow;
    }
  }

  Future<Product> update(Product existing, ProductInput input) async {
    final uploadedUrl =
        input.image == null ? null : await uploadImage(input.image!);
    final Map<String, dynamic> row;
    try {
      row = await _client
          .from(_table)
          .update(_payload(input, uploadedUrl))
          .eq('id', existing.id)
          .select(_select)
          .single();
    } catch (_) {
      if (uploadedUrl != null) await deleteImageByUrl(uploadedUrl);
      rethrow;
    }

    final updated = Product.fromJson(row);
    final oldUrl = existing.imageUrl;
    if (oldUrl != null && oldUrl != updated.imageUrl) {
      await deleteImageByUrl(oldUrl);
    }
    return updated;
  }

  /// Deletes a product and its uploaded image. Past orders keep their
  /// snapshot of the name and price.
  Future<void> delete(Product product) async {
    final deleted = await _client
        .from(_table)
        .delete()
        .eq('id', product.id)
        .select('id');
    if (deleted.isEmpty) {
      // RLS silently filters out rows the user may not delete.
      throw const PostgrestException(
        message: "You don't have permission to delete this product.",
        code: '42501',
      );
    }
    if (product.imageUrl != null) await deleteImageByUrl(product.imageUrl!);
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
    final path = 'products/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Removes a file from the bucket given its public URL. External URLs are
  /// ignored, and cleanup failures never break the main operation.
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
    return Uri.decodeComponent(
      url.substring(i + marker.length).split('?').first,
    );
  }

  static String _escapeLike(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  Map<String, dynamic> _payload(ProductInput input, String? uploadedUrl) {
    String? clean(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();
    return {
      'name': input.name.trim(),
      'description': clean(input.description),
      'price': input.price,
      'stock': input.stock,
      'category_id': input.categoryId,
      'image_url': uploadedUrl ?? clean(input.imageUrl),
    };
  }
}
