class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
      };
}
