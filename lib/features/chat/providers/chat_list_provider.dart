import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_service.dart';

class ChatListState {
  final bool loading;
  final String? error;
  final List<ConversationDto> conversations;
  final int unreadCount;

  const ChatListState({
    this.loading = false,
    this.error,
    this.conversations = const [],
    this.unreadCount = 0,
  });

  ChatListState copyWith({
    bool? loading,
    String? error,
    List<ConversationDto>? conversations,
    int? unreadCount,
  }) {
    return ChatListState(
      loading: loading ?? this.loading,
      error: error,
      conversations: conversations ?? this.conversations,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatListNotifier extends StateNotifier<ChatListState> {
  final ChatRepository _repo;
  final Ref _ref;
  Timer? _pollingTimer;
  ProviderSubscription? _connSub;

  ChatListNotifier(this._repo, this._ref) : super(const ChatListState()) {
    load();
    _startPolling();
    
    // Listen to network changes
    _connSub = _ref.listen<AsyncValue<bool>>(connectivityProvider, (_, next) {
      final online = next.value ?? false;
      if (online) {
        syncPending();
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _connSub?.close();
    super.dispose();
  }

  Future<void> syncPending() async {
    final svc = _ref.read(offlineServiceProvider);
    final ops = await svc.pending();
    final chatOps = ops.where((o) => o.kind == OfflineOpKind.sendChatMessage).toList();
    if (chatOps.isEmpty) return;

    for (final op in chatOps) {
      try {
        final payload = op.payload;
        // Call sync directly to avoid duplicating queue logic
        await _repo.syncMessage(
          uuid: payload['uuid'] as String,
          convId: int.parse(payload['conv_id'] as String),
          type: payload['type'] as String,
          body: payload['body'] as String,
          replyToId: payload['reply_to_id'] != null ? int.parse(payload['reply_to_id'] as String) : null,
        );
        await svc.remove(op.id!);
      } catch (e) {
        await svc.markRetry(op.id!, op.retryCount ?? 0);
      }
    }
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) state = state.copyWith(loading: true, error: null);
    try {
      final conversations = await _repo.getConversations();
      final count = await _repo.getUnreadCount();
      state = state.copyWith(
        loading: false,
        conversations: conversations,
        unreadCount: count,
      );
    } catch (e) {
      if (!silent) state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repo.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }
}

final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier(ref.read(chatRepositoryProvider), ref);
});
