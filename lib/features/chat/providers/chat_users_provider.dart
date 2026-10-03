import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

class ChatUsersState {
  final bool loading;
  final String? error;
  final List<UserDto> users;

  ChatUsersState({this.loading = false, this.error, this.users = const []});

  ChatUsersState copyWith({bool? loading, String? error, List<UserDto>? users}) {
    return ChatUsersState(
      loading: loading ?? this.loading,
      error: error, // overwrite
      users: users ?? this.users,
    );
  }
}

class ChatUsersNotifier extends StateNotifier<ChatUsersState> {
  final ChatRepository _repo;

  ChatUsersNotifier(this._repo) : super(ChatUsersState()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final users = await _repo.getChatUsers();
      state = state.copyWith(loading: false, users: users);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<int?> startPrivateChat(int userId) async {
    try {
      return await _repo.startPrivateChat(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final chatUsersProvider = StateNotifierProvider<ChatUsersNotifier, ChatUsersState>((ref) {
  return ChatUsersNotifier(ref.read(chatRepositoryProvider));
});
