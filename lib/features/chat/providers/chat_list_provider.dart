import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

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
  Timer? _pollingTimer;

  ChatListNotifier(this._repo) : super(const ChatListState()) {
    load();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
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
  return ChatListNotifier(ref.read(chatRepositoryProvider));
});
