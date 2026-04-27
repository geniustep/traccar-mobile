import '../../domain/entities/user_entity.dart';

/// Maps the Traccar `/session` and `/users/{id}` response to [UserEntity].
///
/// Traccar user JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "geniustep",
///   "email": "agsteps@gmail.com",
///   "phone": null,
///   "administrator": true,
///   "readonly": false,
///   "disabled": false,
///   "deviceLimit": -1,
///   "attributes": { "speedUnit": "kmh", "timezone": "..." }
/// }
/// ```
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.administrator = false,
    this.readonly = false,
    this.disabled = false,
    this.deviceLimit = -1,
    this.attributes = const {},
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final bool administrator;
  final bool readonly;
  final bool disabled;
  final int deviceLimit;
  final Map<String, dynamic> attributes;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? json['login'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        administrator: json['administrator'] as bool? ?? false,
        readonly: json['readonly'] as bool? ?? false,
        disabled: json['disabled'] as bool? ?? false,
        deviceLimit: json['deviceLimit'] as int? ?? -1,
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        'administrator': administrator,
        'readonly': readonly,
        'disabled': disabled,
        'deviceLimit': deviceLimit,
        'attributes': attributes,
      };

  UserEntity toEntity() => UserEntity(
        id: id.toString(),
        name: name,
        email: email,
        phone: phone,
        administrator: administrator,
        readonly: readonly,
        disabled: disabled,
        deviceLimit: deviceLimit,
      );
}
