/// A row in the Supabase `items` table.
class Item {
  final int id;
  final DateTime createdAt;
  final String name;
  final String? description;
  final String? imageUrl;

  const Item({
    required this.id,
    required this.createdAt,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}
