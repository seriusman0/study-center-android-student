// Models for admin notifications displayed in the dashboard bell dropdown.
//
// AdminNotification represents a system/user-targeted notification sent to
// an admin user. It follows the same parsing conventions as
// [JurnalOfflineTemplate] and [JurnalPhotoScan] from jurnal_offline_model.dart.
import 'package:flutter/foundation.dart';

/// Shared date parser used by [AdminNotification].
@visibleForTesting
DateTime parseDate(dynamic raw) {
  if (raw == null) return DateTime.now();
  if (raw is DateTime) return raw;
  try {
    return DateTime.parse(raw as String);
  } catch (_) {
    return DateTime.now();
  }
}

class AdminNotification {
  final int id;
  final String type;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AdminNotification({
    required this.id,
    required this.type,
    required this.message,
    this.data,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    final readAtRaw = json['read_at'];
    return AdminNotification(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String? ?? 'system',
      message: json['message'] as String? ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      isRead: readAtRaw != null,
      readAt: readAtRaw != null ? parseDate(readAtRaw) : null,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'data': data,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  /// Human-readable relative time, e.g. "2 min ago", "1 hour ago".
  String relativeTime() {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.toLocal()}';
    }
  }
}
