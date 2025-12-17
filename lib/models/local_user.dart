class LocalUser {
  final String nombres;
  final String primerApellido;
  final String segundoApellido;
  final String telefono;

  const LocalUser({
    required this.nombres,
    required this.primerApellido,
    required this.segundoApellido,
    required this.telefono,
  });

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      nombres: json['nombres'] as String,
      primerApellido: json['primerApellido'] as String,
      segundoApellido: json['segundoApellido'] as String,
      telefono: json['telefono'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombres': nombres,
        'primerApellido': primerApellido,
        'segundoApellido': segundoApellido,
        'telefono': telefono,
      };

  String get nombreCompleto =>
      '$nombres $primerApellido $segundoApellido'.trim();
}
