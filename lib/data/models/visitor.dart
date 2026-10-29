class VisitEvent {
  const VisitEvent({required this.action, required this.timestamp});

  final String action;
  final DateTime timestamp;

  factory VisitEvent.fromJson(Map<String, dynamic> json) => VisitEvent(
    action: json['action'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> toJson() => {
    'action': action,
    'timestamp': timestamp.toIso8601String(),
  };
}

class Visitor {
  const Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    required this.visitorType,
    required this.project,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.email,
    this.checkInTime,
    this.checkOutTime,
    this.history = const [],
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;
  final String status;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final List<VisitEvent> history;

  factory Visitor.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        DateTime.tryParse(json[key]?.toString() ?? '');
    final events = json['history'];
    return Visitor(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email'] as String?,
      visitorType:
          (json['visitor_type'] ?? json['visitorType']) as String? ?? 'Other',
      project: json['project'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      status: json['status'] as String? ?? 'Registered',
      createdAt: date('created_at') ?? DateTime.now(),
      checkInTime: date('check_in_time'),
      checkOutTime: date('check_out_time'),
      history: events is List
          ? events
                .whereType<Map>()
                .map(
                  (event) =>
                      VisitEvent.fromJson(Map<String, dynamic>.from(event)),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mobile': mobile,
    'email': email,
    'visitor_type': visitorType,
    'project': project,
    'purpose': purpose,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'check_in_time': checkInTime?.toIso8601String(),
    'check_out_time': checkOutTime?.toIso8601String(),
    'history': history.map((event) => event.toJson()).toList(),
  };

  Visitor copyWith({
    String? name,
    String? mobile,
    String? email,
    bool clearEmail = false,
    String? visitorType,
    String? project,
    String? purpose,
    String? status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    List<VisitEvent>? history,
  }) => Visitor(
    id: id,
    name: name ?? this.name,
    mobile: mobile ?? this.mobile,
    email: clearEmail ? null : email ?? this.email,
    visitorType: visitorType ?? this.visitorType,
    project: project ?? this.project,
    purpose: purpose ?? this.purpose,
    status: status ?? this.status,
    createdAt: createdAt,
    checkInTime: checkInTime ?? this.checkInTime,
    checkOutTime: checkOutTime ?? this.checkOutTime,
    history: history ?? this.history,
  );
}
