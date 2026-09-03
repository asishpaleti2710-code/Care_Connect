class SosAlert {
  final int id;
  final int residentId;
  final int? userId;
  final String alertType;
  final String category;
  final String? message;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? acknowledgedAt;
  final DateTime? respondingAt;
  final DateTime? resolvedAt;
  final DateTime? cancelledAt;
  final int? responderId;
  final String? responderName;
  final String? responderRole;
  final String? responseNotes;
  final String? residentName;
  final String? residentRoom;
  final double? timeToAcknowledgeSeconds;
  final double? timeToRespondSeconds;
  final double? timeToResolveSeconds;
  final List<SosAuditLog> auditLogs;

  const SosAlert({
    required this.id,
    required this.residentId,
    this.userId,
    required this.alertType,
    required this.category,
    this.message,
    this.latitude,
    this.longitude,
    this.mapsUrl,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.activatedAt,
    this.acknowledgedAt,
    this.respondingAt,
    this.resolvedAt,
    this.cancelledAt,
    this.responderId,
    this.responderName,
    this.responderRole,
    this.responseNotes,
    this.residentName,
    this.residentRoom,
    this.timeToAcknowledgeSeconds,
    this.timeToRespondSeconds,
    this.timeToResolveSeconds,
    this.auditLogs = const [],
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isAcknowledged => status.toUpperCase() == 'ACKNOWLEDGED';
  bool get isResponding => status.toUpperCase() == 'RESPONDING';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    var rawLogs = json['audit_logs'];
    List<SosAuditLog> logs = [];
    if (rawLogs is List) {
      logs = rawLogs.map((l) => SosAuditLog.fromJson(l as Map<String, dynamic>)).toList();
    }

    return SosAlert(
      id: json['id'] as int? ?? 0,
      residentId: json['resident_id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      alertType: json['alert_type'] as String? ?? 'Medical Emergency',
      category: json['category'] as String? ?? json['alert_type'] as String? ?? 'Medical Emergency',
      message: json['message'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapsUrl: json['maps_url'] as String?,
      priority: json['priority'] as String? ?? 'CRITICAL',
      status: (json['status'] as String? ?? 'ACTIVE').toUpperCase(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      activatedAt: json['activated_at'] != null ? DateTime.tryParse(json['activated_at'].toString()) : null,
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.tryParse(json['acknowledged_at'].toString()) : null,
      respondingAt: json['responding_at'] != null ? DateTime.tryParse(json['responding_at'].toString()) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'].toString()) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.tryParse(json['cancelled_at'].toString()) : null,
      responderId: json['responder_id'] as int?,
      responderName: json['responder_name'] as String?,
      responderRole: json['responder_role'] as String?,
      responseNotes: json['response_notes'] as String?,
      residentName: json['resident_name'] as String?,
      residentRoom: json['resident_room'] as String?,
      timeToAcknowledgeSeconds: (json['time_to_acknowledge_seconds'] as num?)?.toDouble(),
      timeToRespondSeconds: (json['time_to_respond_seconds'] as num?)?.toDouble(),
      timeToResolveSeconds: (json['time_to_resolve_seconds'] as num?)?.toDouble(),
      auditLogs: logs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resident_id': residentId,
      'user_id': userId,
      'alert_type': alertType,
      'category': category,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'maps_url': mapsUrl,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SosAuditLog {
  final int id;
  final int sosId;
  final String? previousStatus;
  final String newStatus;
  final String? actionByName;
  final String? actionByRole;
  final String? notes;
  final DateTime createdAt;

  const SosAuditLog({
    required this.id,
    required this.sosId,
    this.previousStatus,
    required this.newStatus,
    this.actionByName,
    this.actionByRole,
    this.notes,
    required this.createdAt,
  });

  factory SosAuditLog.fromJson(Map<String, dynamic> json) {
    return SosAuditLog(
      id: json['id'] as int? ?? 0,
      sosId: json['sos_id'] as int? ?? 0,
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String? ?? 'ACTIVE',
      actionByName: json['action_by_name'] as String?,
      actionByRole: json['action_by_role'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SosNotificationItem {
  final int id;
  final int? sosId;
  final String? recipientRole;
  final String? recipientName;
  final String channel;
  final String title;
  final String message;
  final String status;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? failureReason;

  const SosNotificationItem({
    required this.id,
    this.sosId,
    this.recipientRole,
    this.recipientName,
    required this.channel,
    required this.title,
    required this.message,
    required this.status,
    required this.isRead,
    required this.createdAt,
    this.deliveredAt,
    this.failureReason,
  });

  factory SosNotificationItem.fromJson(Map<String, dynamic> json) {
    return SosNotificationItem(
      id: json['id'] as int? ?? 0,
      sosId: json['sos_id'] as int?,
      recipientRole: json['recipient_role'] as String?,
      recipientName: json['recipient_name'] as String?,
      channel: json['channel'] as String? ?? 'IN_APP',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'DELIVERED',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null,
      failureReason: json['failure_reason'] as String?,
    );
  }
}
