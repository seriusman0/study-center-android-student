import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? loading,
    String? error,
    bool clearUser = false,
  }) =>
      AuthState(
        user:    clearUser ? null : (user ?? this.user),
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
      state = AuthState(user: user);
    } on AccessDeniedException {
      state = const AuthState(error: 'Akses ditolak: Anda bukan mahasiswa aktif.');
    } catch (e) {
      state = AuthState(error: extractErrorMessage(e));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
          );
      state = AuthState(user: user);
    } catch (e) {
      state = AuthState(error: extractErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Ensure local token is cleared even if server call fails
      await ref.read(storageServiceProvider).deleteToken();
    } finally {
      state = const AuthState();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Called after profile update to keep local state in sync.
  void setUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> restoreSession() async {
    final token = await ref.read(storageServiceProvider).getToken();
    if (token == null) return;
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(user: user);
    } catch (_) {
      await ref.read(storageServiceProvider).deleteToken();
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
