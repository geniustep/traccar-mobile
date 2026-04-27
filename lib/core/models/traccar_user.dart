/// Traccar User — maps to `/users` and `/session` API endpoints.
class TraccarUser {
  const TraccarUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.readonly = false,
    this.administrator = false,
    this.disabled = false,
    this.deviceLimit = -1,
    this.userLimit = 0,
    this.expirationTime,
    this.token,
    this.attributes = const {},
  });

  final int id;
  final String name;
  final String email;
  final String? phone;

  /// Read-only users can view but not modify
  final bool readonly;

  /// Administrator has full access
  final bool administrator;

  final bool disabled;

  /// Max devices this user may register (-1 = unlimited)
  final int deviceLimit;

  /// Max sub-users this user may create
  final int userLimit;

  final DateTime? expirationTime;

  /// API token for token-based auth (alternative to session cookies)
  final String? token;

  final Map<String, dynamic> attributes;

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get isAdmin => administrator;
  bool get isReadOnly => readonly;
  bool get isExpired =>
      expirationTime != null && expirationTime!.isBefore(DateTime.now());
  bool get hasUnlimitedDevices => deviceLimit == -1;

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory TraccarUser.fromJson(Map<String, dynamic> json) => TraccarUser(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        readonly: json['readonly'] as bool? ?? false,
        administrator: json['administrator'] as bool? ?? false,
        disabled: json['disabled'] as bool? ?? false,
        deviceLimit: json['deviceLimit'] as int? ?? -1,
        userLimit: json['userLimit'] as int? ?? 0,
        expirationTime: json['expirationTime'] == null
            ? null
            : DateTime.tryParse(json['expirationTime'] as String),
        token: json['token'] as String?,
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        'readonly': readonly,
        'administrator': administrator,
        'disabled': disabled,
        'deviceLimit': deviceLimit,
        'userLimit': userLimit,
        if (expirationTime != null)
          'expirationTime': expirationTime!.toIso8601String(),
        if (token != null) 'token': token,
        'attributes': attributes,
      };

  TraccarUser copyWith({
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? attributes,
  }) =>
      TraccarUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        readonly: readonly,
        administrator: administrator,
        disabled: disabled,
        deviceLimit: deviceLimit,
        userLimit: userLimit,
        expirationTime: expirationTime,
        token: token,
        attributes: attributes ?? this.attributes,
      );

  @override
  String toString() =>
      'TraccarUser(id: $id, name: $name, admin: $administrator)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TraccarUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
