class Parada {
  final int? idParada;
  final double lat;
  final double lon;
  final String nombre;
  final String direccion;
  final bool estado;

  Parada({
    this.idParada,
    required this.lat,
    required this.lon,
    required this.nombre,
    required this.direccion,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_parada': idParada,
      'latitud': lat,
      'longitud': lon,
      'nombre': nombre,
      'direccion': direccion,
      'estado': estado ? 1 : 0,
    };
  }

  factory Parada.fromMap(Map<String, dynamic> map) {
    return Parada(
      idParada: map['id_parada'],
      lat: map['latitud'],
      lon: map['longitud'],
      nombre: map['nombre'],
      direccion: map['direccion'],
      estado: map['estado'] == 1,
    );
  }
}
