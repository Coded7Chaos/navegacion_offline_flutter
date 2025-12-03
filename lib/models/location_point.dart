enum LocationPointType { location, stop }

class LocationPoint {
  const LocationPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.address,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final LocationPointType type;
  final String? address;

  factory LocationPoint.fromMap(Map<String, Object?> map, LocationPointType type) {
    return LocationPoint(
      id: (map['id'] as int?) ?? (map['id_ubicacion'] as int?) ?? (map['id_parada'] as int?) ?? 0,
      name: (map['nombre'] as String?) ?? '',
      latitude: (map['latitud'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitud'] as num?)?.toDouble() ?? 0,
      type: type,
      address: map['direccion'] as String?,
    );
  }
}
