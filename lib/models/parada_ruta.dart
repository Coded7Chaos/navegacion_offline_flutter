class ParadaRuta {
  final int idRuta;
  final int idParada;
  final int orden;
  final int tiempo;
  final int idCoordenada;

  ParadaRuta({
    required this.idRuta,
    required this.idParada,
    required this.orden,
    required this.tiempo,
    required this.idCoordenada,
  });

  factory ParadaRuta.fromMap(Map<String, dynamic> map) {
    return ParadaRuta(
      idRuta: map['id_ruta'],
      idParada: map['id_parada'],
      orden: map['orden'],
      tiempo: map['tiempo'],
      idCoordenada: map['id_coordenada'],
    );
  }
}
