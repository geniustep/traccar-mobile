class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.administrator = false,
    this.readonly = false,
    this.disabled = false,
    this.deviceLimit = -1,
    this.attributes = const {},
    // Legacy / display helpers
    this.avatarUrl,
    this.organization,
  });

  /// Traccar user id (stored as String for consistency across the app)
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool administrator;
  final bool readonly;
  final bool disabled;
  final int deviceLimit;

  /// Traccar user attributes (e.g. `{'speedUnit': 'kmh', 'appRole': 'technician'}`).
  final Map<String, dynamic> attributes;

  // ── Display helpers ───────────────────────────────────────────────────────

  final String? avatarUrl;
  final String? organization;

  String get role => administrator ? 'administrator' : (readonly ? 'readonly' : 'user');
  bool get hasUnlimitedDevices => deviceLimit == -1;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  UserEntity copyWith({
    String? name,
    String? email,
    String? phone,
    bool? administrator,
    bool? readonly,
    bool? disabled,
    Map<String, dynamic>? attributes,
    String? avatarUrl,
    String? organization,
  }) =>
      UserEntity(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        administrator: administrator ?? this.administrator,
        readonly: readonly ?? this.readonly,
        disabled: disabled ?? this.disabled,
        deviceLimit: deviceLimit,
        attributes: attributes ?? this.attributes,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        organization: organization ?? this.organization,
      );
}
