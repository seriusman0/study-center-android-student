import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/services/api_service.dart';

class AuthState {
  final UserModel? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? loading, String? error}) =>
      AuthState(
        user:    user ?? this.user,
        loading: loading ?? this.loading,
        error:   error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      state = state.copyWith(user: user, loading: false);
    } on AccessDeniedException {
      state = AuthState(error: 'Akses ditolak: Anda bukan mahasiswa');
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> restoreSession() async {
    final token = await ref.read(storageServiceProvider).getToken();
    if (token == null) return;
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = state.copyWith(user: user);
    } catch (_) {
      await ref.read(storageServiceProvider).deleteToken();
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
