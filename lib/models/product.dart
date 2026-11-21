import '../utils/format.dart';

/// A row in the Supabase `products` table (with its category name joined in).
class Product {
  final int id;
  final DateTime createdAt;
  final String name;
  final String? description;
  final int stock;
  final String? imageUrl;
  final int categoryId;
  final String? categoryName;
  final double price;

  const Product({
    required this.id,
    required this.createdAt,
    required this.name,
    this.description,
    required this.stock,
    this.imageUrl,
    required this.categoryId,
    this.categoryName,
    required this.price,
  });

  bool get inStock => stock > 0;

  String get displayPrice => formatMoney(price);

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: category?['name'] as String?,
      price: parseDouble(json['price']),
    );
  }
}
