/// Represents a Guatemalan supermarket chain supported by Food Friend.
///
/// Structured with [isFavorite] so users can track preferred stores
/// across current and future iterations.
class Supermarket {
  const Supermarket({
    required this.id,
    required this.name,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final bool isFavorite;

  Supermarket copyWith({
    String? id,
    String? name,
    bool? isFavorite,
  }) {
    return Supermarket(
      id: id ?? this.id,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isFavorite': isFavorite,
      };

  factory Supermarket.fromJson(Map<String, dynamic> json) {
    return Supermarket(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isFavorite: json['isFavorite'] == true,
    );
  }

  /// Default directory of supported Guatemalan supermarket chains.
  static const List<Supermarket> knownSupermarkets = [
    Supermarket(id: 'latorre', name: 'La Torre'),
    Supermarket(id: 'walmart', name: 'Walmart'),
  ];
}
