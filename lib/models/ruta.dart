class Ruta {
  final int? idRutaPuma;
  final String nombre;
  final String sentido;
  final bool estado;

  Ruta({
    this.idRutaPuma,
    required this.nombre,
    required this.sentido,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_ruta_puma': idRutaPuma,
      'nombre': nombre,
      'sentido': sentido,
      'estado': estado ? 1 : 0,
    };
  }

  factory Ruta.fromMap(Map<String, dynamic> map) {
    return Ruta(
      idRutaPuma: map['id_ruta_puma'],
      nombre: map['nombre'],
      sentido: map['sentido'],
      estado: map['estado'] == 1,
    );
  }
}
