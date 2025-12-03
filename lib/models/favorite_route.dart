class FavoriteRoute {
  const FavoriteRoute({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;

  factory FavoriteRoute.fromMap(Map<dynamic, dynamic> map) {
    return FavoriteRoute(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
      };
}
