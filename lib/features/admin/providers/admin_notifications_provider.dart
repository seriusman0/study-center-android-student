import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/admin_notification_model.dart';

/// Repository for admin notifications.
///
/// Follows the same inline-repository pattern used by
/// [JurnalOfflineRepository] and [AdminDashboardRepository].
class AdminNotificationsRepository {
  final Dio _dio;
  const AdminNotificationsRepository(this._dio);

  /// GET /admin/admin-notifications?unread_only=1
  /// Returns a paginated list of admin notifications (latest first).
  Future<List<AdminNotification>> fetch({bool unreadOnly = false}) async {
    final response = await _dio.get(
      ApiConstants.adminNotifications,
      queryParameters: unreadOnly ? {'unread_only': '1'} : null,
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data
        .map((e) => AdminNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /admin/admin-notifications/{id}/mark-read
  /// Marks a single notification as read.
  Future<void> markRead(int id) async {
    await _dio.post(ApiConstants.adminNotificationMarkRead(id));
  }
}

final adminNotificationsRepositoryProvider = Provider(
  (ref) => AdminNotificationsRepository(ref.read(dioProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────────

class AdminNotificationsState {
  final bool loading;
  final List<AdminNotification> notifications;
  final String? error;

  const AdminNotificationsState({
    this.loading = false,
    this.notifications = const [],
    this.error,
  });

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;
}

class AdminNotificationsNotifier
    extends Notifier<AdminNotificationsState> {
  Timer? _pollTimer;

  @override
  AdminNotificationsState build() {
    // Poll every 30 seconds, matching the requirement.
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    ref.onDispose(() => _pollTimer?.cancel());
    return const AdminNotificationsState();
  }

  Future<void> load() async {
    state = const AdminNotificationsState(loading: true);
    try {
      final notifications =
          await ref.read(adminNotificationsRepositoryProvider).fetch();
      state = AdminNotificationsState(notifications: notifications);
    } catch (e) {
      state = AdminNotificationsState(error: extractErrorMessage(e));
    }
  }

  /// Public refresh used both by pull-to-refresh and the 30 s poll timer.
  Future<void> refresh() async {
    try {
      final notifications =
          await ref.read(adminNotificationsRepositoryProvider).fetch();
      state = AdminNotificationsState(notifications: notifications);
    } catch (e) {
      state = AdminNotificationsState(
        notifications: state.notifications,
        error: extractErrorMessage(e),
      );
    }
  }

  Future<bool> markRead(int id) async {
    try {
      await ref.read(adminNotificationsRepositoryProvider).markRead(id);
      await refresh();
      return true;
    } catch (e) {
      state = AdminNotificationsState(
        notifications: state.notifications,
        error: extractErrorMessage(e),
      );
      return false;
    }
  }
}

final adminNotificationsProvider = NotifierProvider<
    AdminNotificationsNotifier, AdminNotificationsState>(
  AdminNotificationsNotifier.new);
