import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A minimal profile snapshot saved after each successful login.
/// Stored as JSON in secure storage so the user can switch back
/// to a previously-used account with one tap (no password needed
/// as long as the token hasn't expired server-side).
class SavedProfile {
  final int userId;
  final String name;
  final String email;
  final String? avatar;
  final String primaryRole;
  final String token;
  final DateTime savedAt;

  const SavedProfile({
    required this.userId,
    required this.name,
    required this.email,
    this.avatar,
    required this.primaryRole,
    required this.token,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
        'avatar': avatar,
        'primaryRole': primaryRole,
        'token': token,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedProfile.fromJson(Map<String, dynamic> json) => SavedProfile(
        userId: (json['userId'] as num).toInt(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatar: json['avatar'] as String?,
        primaryRole: json['primaryRole'] as String? ?? 'student',
        token: json['token'] as String? ?? '',
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _profilesKey = 'saved_profiles';
  final _storage = const FlutterSecureStorage();

  // ── Active token ──────────────────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ── Saved profiles (multi-account quick-switch) ───────────────────────

  /// Returns all saved profiles, newest-first.
  Future<List<SavedProfile>> getSavedProfiles() async {
    final raw = await _storage.read(key: _profilesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final profiles =
          list.map((e) => SavedProfile.fromJson(e as Map<String, dynamic>)).toList();
      profiles.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return profiles;
    } catch (_) {
      return [];
    }
  }

  /// Upserts a profile (by userId). If the user already has a saved profile
  /// the token & timestamp are refreshed; otherwise a new entry is added.
  /// Keeps at most 10 profiles.
  Future<void> saveProfile(SavedProfile profile) async {
    final profiles = await getSavedProfiles();
    profiles.removeWhere((p) => p.userId == profile.userId);
    profiles.insert(0, profile);
    if (profiles.length > 10) profiles.removeLast();
    await _storage.write(
        key: _profilesKey, value: jsonEncode(profiles.map((p) => p.toJson()).toList()));
  }

  /// Remove a specific saved profile (e.g. user long-presses to forget).
  Future<void> removeSavedProfile(int userId) async {
    final profiles = await getSavedProfiles();
    profiles.removeWhere((p) => p.userId == userId);
    await _storage.write(
        key: _profilesKey, value: jsonEncode(profiles.map((p) => p.toJson()).toList()));
  }
}
