class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.organization,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? phone;
  final String? organization;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    String? phone,
    String? organization,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      organization: organization ?? this.organization,
    );
  }
}
