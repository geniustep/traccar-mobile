/// Traccar Device — represents a GPS tracking unit.
/// Maps to the `/devices` API endpoint response.
class TraccarDevice {
  const TraccarDevice({
    required this.id,
    required this.name,
    required this.uniqueId,
    required this.status,
    this.lastUpdate,
    this.groupId,
    this.phone,
    this.model,
    this.contact,
    this.category,
    this.disabled = false,
    this.attributes = const {},
  });

  final int id;
  final String name;

  /// Device IMEI or identifier sent by the tracker hardware
  final String uniqueId;

  /// online | offline | unknown
  final String status;

  final DateTime? lastUpdate;
  final int? groupId;
  final String? phone;
  final String? model;
  final String? contact;

  /// car | truck | motorcycle | boat | bicycle | etc.
  final String? category;

  final bool disabled;

  /// Extra key-value pairs from Traccar
  final Map<String, dynamic> attributes;

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get isOnline => status == 'online';
  bool get isOffline => status == 'offline';
  bool get isDisabled => disabled;

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory TraccarDevice.fromJson(Map<String, dynamic> json) => TraccarDevice(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'Unknown',
        uniqueId: json['uniqueId'] as String? ?? '',
        status: json['status'] as String? ?? 'offline',
        lastUpdate: json['lastUpdate'] == null
            ? null
            : DateTime.tryParse(json['lastUpdate'] as String),
        groupId: json['groupId'] as int?,
        phone: json['phone'] as String?,
        model: json['model'] as String?,
        contact: json['contact'] as String?,
        category: json['category'] as String?,
        disabled: json['disabled'] as bool? ?? false,
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'uniqueId': uniqueId,
        'status': status,
        if (lastUpdate != null) 'lastUpdate': lastUpdate!.toIso8601String(),
        if (groupId != null) 'groupId': groupId,
        if (phone != null) 'phone': phone,
        if (model != null) 'model': model,
        if (contact != null) 'contact': contact,
        if (category != null) 'category': category,
        'disabled': disabled,
        'attributes': attributes,
      };

  TraccarDevice copyWith({
    String? name,
    String? status,
    DateTime? lastUpdate,
    int? groupId,
    bool? disabled,
    Map<String, dynamic>? attributes,
  }) =>
      TraccarDevice(
        id: id,
        name: name ?? this.name,
        uniqueId: uniqueId,
        status: status ?? this.status,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        groupId: groupId ?? this.groupId,
        phone: phone,
        model: model,
        contact: contact,
        category: category,
        disabled: disabled ?? this.disabled,
        attributes: attributes ?? this.attributes,
      );

  @override
  String toString() => 'TraccarDevice(id: $id, name: $name, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TraccarDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
