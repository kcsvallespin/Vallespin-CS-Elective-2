class Pokemon {
  final int id;
  final String name;
  final String imageUrl;

  const Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  /// Builds a Pokemon from one entry of the /pokemon list endpoint.
  /// Each entry looks like: { "name": "bulbasaur", "url": ".../pokemon/1/" }
  /// The list endpoint has no ID or image fields, so the ID is read from the
  /// URL and the image URL is built from that ID.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final segments = Uri.parse(url).pathSegments.where((s) => s.isNotEmpty);
    final id = int.parse(segments.last);

    return Pokemon(
      id: id,
      name: json['name'] as String,
      imageUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png',
    );
  }

  /// "bulbasaur" -> "Bulbasaur"
  String get displayName =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);

  /// 1 -> "#001"
  String get displayId => '#${id.toString().padLeft(3, '0')}';
}
