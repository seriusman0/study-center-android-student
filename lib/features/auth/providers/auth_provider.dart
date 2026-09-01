import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final bool loading;
  final String? error;
  final String? expiredEmail; // email whose token expired (pre-fill on manual form)

  const AuthState({this.user, this.loading = false, this.error, this.expiredEmail});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? loading,
    String? error,
    String? expiredEmail,
    bool clearUser = false,
  }) =>
      AuthState(
        user:         clearUser ? null : (user ?? this.user),
        loading:      loading ?? this.loading,
        error:        error,
        expiredEmail:  expiredEmail,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  /// Last known password for auto re-login on token expiry.
  String? _lastPassword;

  /// Saves a password to be used for auto re-login if the token expires.
  void rememberPassword(String password) {
    _lastPassword = password;
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      state = AuthState(user: user);
      _lastPassword = password;

      // Persist token + profile so restoreSession() can recover the session
      // on next launch (critical for offline behaviour).
      final token = await ref.read(storageServiceProvider).getToken();
      if (token != null) {
        await ref.read(storageServiceProvider).saveProfile(SavedProfile(
          userId: user.id,
          name: user.name,
          email: user.email,
          avatar: user.avatar,
          primaryRole: user.primaryRole,
          token: token,
          password: password, // <-- auto re-login support
          savedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      _lastPassword = null;
      state = AuthState(error: extractErrorMessage(e));
    }
  }

  /// Quick-switch from a previously saved profile.
  ///
  /// 1. Validate token via GET /me
  /// 2. If token expired → auto re-login with stored password (if any)
  /// 3. If no stored password → show manual login form
  Future<void> loginWithProfile(SavedProfile profile) async {
    state = state.copyWith(loading: true, error: null);

    // Step 1: Try token validation
    try {
      await ref.read(storageServiceProvider).saveToken(profile.token);
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(user: user);

      // Refresh profile snapshot
      await ref.read(storageServiceProvider).saveProfile(SavedProfile(
        userId: user.id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        primaryRole: user.primaryRole,
        token: profile.token,
        password: profile.password, // preserve stored password
        savedAt: DateTime.now(),
      ));
      return;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        // Token expired — step 2: try auto re-login with stored password
        if (profile.password != null && profile.password!.isNotEmpty) {
          debugPrint('[Auth] Token expired, attempting auto re-login for ${profile.email}');
          final success = await _autoLogin(profile.email, profile.password!);
          if (success) return;
          // Auto login failed — fall through to manual
        }
      }
    } catch (_) {}

    // Step 3: No stored password or auto re-login failed — show manual form
    await ref.read(storageServiceProvider).removeSavedProfile(profile.userId);
    state = AuthState(
      error: 'Sesi habis. Silakan login ulang.',
      expiredEmail: profile.email,
    );
    // Pre-fill email so user only needs password
    // (handled in LoginScreen via the error + savedProfiles state)
  }

  /// Attempts silent login with email + password. Returns true on success.
  Future<bool> _autoLogin(String email, String password) async {
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      state = AuthState(user: user);
      _lastPassword = password;

      final token = await ref.read(storageServiceProvider).getToken();
      if (token != null) {
        await ref.read(storageServiceProvider).saveProfile(SavedProfile(
          userId: user.id,
          name: user.name,
          email: user.email,
          avatar: user.avatar,
          primaryRole: user.primaryRole,
          token: token,
          password: password,
          savedAt: DateTime.now(),
        ));
      }
      debugPrint('[Auth] Auto re-login success for $email');
      return true;
    } catch (e) {
      debugPrint('[Auth] Auto re-login failed for $email: $e');
      return false;
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
    final storage = ref.read(storageServiceProvider);
    final token = await storage.getToken();
    if (token == null) return;

    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(user: user);
    } catch (_) {
      // Network error — likely offline. Restore user from the most recently
      // saved profile so the app is usable without connectivity.
      final profiles = await storage.getSavedProfiles();
      if (profiles.isNotEmpty) {
        // Use the most recently saved profile as a fallback user.
        final saved = profiles.first;
        final cached = SavedProfile(
          userId: saved.userId,
          name: saved.name,
          email: saved.email,
          avatar: saved.avatar,
          primaryRole: saved.primaryRole,
          token: token, // keep existing token for re-validation later
          password: saved.password,
          savedAt: saved.savedAt,
        );
        // Reconstruct a UserModel from the saved profile.
        state = AuthState(
          user: UserModel(
            id: cached.userId,
            name: cached.name,
            username: cached.email.split('@').first,
            email: cached.email,
            avatar: cached.avatar,
            roles: [cached.primaryRole],
          ),
        );
        debugPrint('[Auth] Offline restore: using cached profile for ${cached.email}');
      } else {
        // No profile and no network — just keep the token for re-validation later.
        debugPrint('[Auth] Offline restore: no cached profile, token preserved');
      }
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Exposes the list of saved profiles for the login screen's quick-switch UI.
final savedProfilesProvider = FutureProvider<List<SavedProfile>>((ref) {
  return ref.read(storageServiceProvider).getSavedProfiles();
});
