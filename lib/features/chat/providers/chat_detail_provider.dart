import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_socket_service.dart';

class ChatDetailState {
  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<MessageDto> messages;
  final int currentPage;
  final int lastPage;
  final String typingUserName;

  const ChatDetailState({
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.messages = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.typingUserName = '',
  });

  ChatDetailState copyWith({
    bool? loading,
    bool? loadingMore,
    String? error,
    List<MessageDto>? messages,
    int? currentPage,
    int? lastPage,
    String? typingUserName,
  }) {
    return ChatDetailState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      messages: messages ?? this.messages,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      typingUserName: typingUserName ?? this.typingUserName,
    );
  }
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  final ChatRepository _repo;
  final ChatSocketService _socket;
  final int convId;

  ChatDetailNotifier(this._repo, this._socket, this.convId) : super(const ChatDetailState()) {
    _init();
  }

  Future<void> _init() async {
    await loadInitial();
    await _repo.markRead(convId);

    _socket.connect(
      onConnected: () {
        _socket.subscribeConversation(convId, _onSocketEvent);
      },
    );
  }

  @override
  void dispose() {
    _socket.unsubscribeConversation(convId);
    super.dispose();
  }

  void _onSocketEvent(dynamic event) {
    if (event is ChannelReadEvent) {
      final eventName = event.name;
      final dataStr = event.data;
      if (dataStr == null) return;
      
      if (eventName == 'MessageSent' || eventName == 'App\\Events\\MessageSent') {
        try {
          final data = dataStr is String ? jsonDecode(dataStr) as Map<String, dynamic> : dataStr as Map<String, dynamic>;
          final message = MessageDto.fromJson(data);
          if (!state.messages.any((m) => m.id == message.id)) {
            state = state.copyWith(
              messages: [message, ...state.messages],
            );
            _repo.markRead(convId);
          }
        } catch (e) {
          debugPrint('[ChatDetail] Error parsing MessageSent: $e');
        }
      } else if (eventName == 'client-typing') {
        try {
          final data = dataStr is String ? jsonDecode(dataStr) as Map<String, dynamic> : dataStr as Map<String, dynamic>;
          final name = data['name'] as String;
          state = state.copyWith(typingUserName: name);
          // Clear typing indicator after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && state.typingUserName == name) {
              state = state.copyWith(typingUserName: '');
            }
          });
        } catch (e) {
          debugPrint('[ChatDetail] Error parsing typing event: $e');
        }
      }
    }
  }

  Future<void> loadInitial() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _repo.getMessages(convId, page: 1);
      final rawList = res['data'] as List? ?? [];
      final list = rawList.where((e) => e is Map).map((e) => MessageDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      state = state.copyWith(
        loading: false,
        messages: list,
        currentPage: 1,
        lastPage: res['last_page'] as int? ?? 1,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.currentPage >= state.lastPage) return;

    state = state.copyWith(loadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final res = await _repo.getMessages(convId, page: nextPage);
      final rawList = res['data'] as List? ?? [];
      final list = rawList.where((e) => e is Map).map((e) => MessageDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      
      state = state.copyWith(
        loadingMore: false,
        messages: [...state.messages, ...list],
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false);
    }
  }

  Future<void> sendTextMessage(String text) async {
    try {
      final message = await _repo.sendMessage(
        convId: convId,
        type: 'text',
        body: text,
      );
      if (!state.messages.any((m) => m.id == message.id)) {
        state = state.copyWith(messages: [message, ...state.messages]);
      }
    } catch (e) {
      debugPrint('[ChatDetail] Send text error: $e');
    }
  }

  Future<void> sendTyping(int userId, String userName) async {
    await _socket.sendTyping(convId, userId, userName);
  }
}

final chatDetailProvider = StateNotifierProvider.family<ChatDetailNotifier, ChatDetailState, int>((ref, convId) {
  return ChatDetailNotifier(
    ref.read(chatRepositoryProvider),
    ref.read(chatSocketServiceProvider),
    convId,
  );
});
