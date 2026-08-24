import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_notification_model.dart';
import '../providers/admin_notifications_provider.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(adminNotificationsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNotificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Admin'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (state.notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai semua',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminNotificationsProvider.notifier).load(),
        child: state.loading && state.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.notifications.isEmpty
                ? Center(child: Text('Gagal memuat: ${state.error}'))
                : state.notifications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Tidak ada notifikasi',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, i) =>
                            _NotifTile(notif: state.notifications[i]),
                      ),
      ),
    );
  }

  Future<void> _markAllRead() async {
    final notifs = ref.read(adminNotificationsProvider).notifications;
    for (final n in notifs.where((n) => !n.isRead)) {
      await ref.read(adminNotificationsProvider.notifier).markRead(n.id);
    }
  }
}

class _NotifTile extends ConsumerWidget {
  final AdminNotification notif;
  const _NotifTile({required this.notif});

  IconData _icon() {
    switch (notif.type) {
      case 'jurnal_alert':
        return Icons.book_outlined;
      case 'pendaftaran':
        return Icons.app_registration;
      case 'blog_moderation':
        return Icons.comment_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notif.isRead;
    return ListTile(
      tileColor: isUnread ? Colors.blue.shade50 : null,
      leading: CircleAvatar(
        backgroundColor: isUnread ? Colors.blue : Colors.grey.shade300,
        child: Icon(_icon(),
            color: isUnread ? Colors.white : Colors.grey, size: 20),
      ),
      title: Text(notif.message,
          style: TextStyle(
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal)),
      subtitle: Text(notif.relativeTime(),
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: isUnread
          ? TextButton(
              onPressed: () =>
                  ref.read(adminNotificationsProvider.notifier).markRead(notif.id),
              child: const Text('Baca', style: TextStyle(fontSize: 12)),
            )
          : null,
    );
  }
}
