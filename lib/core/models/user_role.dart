import '../../features/auth/domain/entities/user_entity.dart';

/// Application-level user role derived from [UserEntity].
///
/// Traccar natively supports only `administrator` (bool) and `readonly` (bool).
/// A `technician` role is inferred from `UserEntity.attributes['appRole']`.
enum UserRole {
  /// Read-only access — can only view device info, no command sending.
  viewer,

  /// Standard operator — can send safe (Low/Medium risk) commands.
  operator,

  /// Fleet technician — can send medium risk, maintenance, and some high risk
  /// commands (engine stop/resume, outputs). Cannot access admin-only commands.
  technician,

  /// Full administrator — unrestricted access including factory reset,
  /// server address, APN, and immobilizer commands.
  admin;

  String get labelFr => switch (this) {
        UserRole.viewer => 'Lecteur',
        UserRole.operator => 'Opérateur',
        UserRole.technician => 'Technicien',
        UserRole.admin => 'Administrateur',
      };

  String get labelAr => switch (this) {
        UserRole.viewer => 'قارئ',
        UserRole.operator => 'مشغّل',
        UserRole.technician => 'تقني',
        UserRole.admin => 'مدير',
      };

  /// True if this role is at least as privileged as [other].
  bool isAtLeast(UserRole other) => index >= other.index;

  bool get isAtLeastOperator => isAtLeast(UserRole.operator);
  bool get isAtLeastTechnician => isAtLeast(UserRole.technician);
  bool get isAdmin => this == UserRole.admin;
}

extension UserEntityRoleX on UserEntity {
  /// Derives the app [UserRole] from Traccar user flags and custom attributes.
  UserRole get appRole {
    if (administrator) return UserRole.admin;
    if (readonly) return UserRole.viewer;
    final roleAttr = attributes['appRole'] as String?;
    if (roleAttr == 'technician') return UserRole.technician;
    return UserRole.operator;
  }
}
