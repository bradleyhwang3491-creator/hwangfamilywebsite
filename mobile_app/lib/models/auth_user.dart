class AuthUser {
  final String id;
  final String username;
  final String name;
  final String? phoneNumber;
  final String role;
  final String? avatarUrl;

  AuthUser({
    required this.id,
    required this.username,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        username: json['username'] as String,
        name: json['name'] as String,
        phoneNumber: json['phone_number'] as String?,
        role: json['role'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'phone_number': phoneNumber,
        'role': role,
        'avatar_url': avatarUrl,
      };
}
