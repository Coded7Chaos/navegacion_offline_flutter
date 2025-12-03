class User {
  final String email;
  final String nombre;
  final int contrasenia; // Keeping as int to match Kotlin, though usually String
  final int edad;

  User({
    required this.email,
    required this.nombre,
    required this.contrasenia,
    required this.edad,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nombre': nombre,
      'contrasenia': contrasenia,
      'edad': edad,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'],
      nombre: map['nombre'],
      contrasenia: map['contrasenia'],
      edad: map['edad'],
    );
  }
}
