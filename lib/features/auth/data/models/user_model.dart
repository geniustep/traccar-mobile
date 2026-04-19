import '../../domain/entities/user_entity.dart';

class UserModel {
  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      organization: json['organization'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (phone != null) 'phone': phone,
        if (organization != null) 'organization': organization,
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        name: name,
        email: email,
        role: role,
        avatarUrl: avatarUrl,
        phone: phone,
        organization: organization,
      );
}
