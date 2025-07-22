class RoleUser {
  final String id;
  final String firstName;
  final String lastName;
  final String role;

  RoleUser({required this.id, required this.firstName, required this.lastName, required this.role});

  factory RoleUser.fromJson(Map<String, dynamic> json) {
    return RoleUser(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'],
    );
  }

  String get fullName => '$firstName $lastName';
} 