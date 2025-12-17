class Notificacion {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String informacion;
  final int rutaAfectada;
  final int rutaAuxiliar;
  final List<int> paradasAfectadas;

  Notificacion({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.informacion,
    required this.rutaAfectada,
    required this.rutaAuxiliar,
    required this.paradasAfectadas,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      informacion: json['informacion'] ?? '',
      rutaAfectada: json['ruta_afectada'] ?? 0,
      rutaAuxiliar: json['ruta_auxiliar'] ?? 0,
      paradasAfectadas: json['paradas_afectadas'] != null 
          ? List<int>.from(json['paradas_afectadas'])
          : [],
    );
  }
}
