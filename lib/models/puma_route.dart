class PumaRoute {
  const PumaRoute({
    required this.id,
    required this.name,
    required this.direction,
    required this.isActive,
  });

  final int id;
  final String name;
  final String direction;
  final bool isActive;

  factory PumaRoute.fromMap(Map<String, Object?> map) {
    return PumaRoute(
      id: (map['id_ruta_puma'] as int?) ?? (map['id_ruta'] as int?) ?? 0,
      name: (map['nombre'] as String?) ?? '',
      direction: (map['sentido'] as String?) ?? '',
      isActive: ((map['estado'] as int?) ?? 0) == 1,
    );
  }
}
