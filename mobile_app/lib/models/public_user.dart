class PublicUser {
  final String id;
  final String name;
  final String? avatarUrl;

  PublicUser({required this.id, required this.name, required this.avatarUrl});

  factory PublicUser.fromJson(Map<String, dynamic> json) => PublicUser(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );
}
