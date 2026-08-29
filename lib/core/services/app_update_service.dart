import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api_constants.dart';

/// Holds the result of a version check against the backend.
class AppUpdateInfo {
  final String latestVersion;
  final int latestBuild;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final String minVersion;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.minVersion,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
        latestVersion: json['latest_version'] as String? ?? '0.0.0',
        latestBuild: (json['latest_build'] as num?)?.toInt() ?? 0,
        downloadUrl: json['download_url'] as String? ?? '',
        releaseNotes: json['release_notes'] as String? ?? '',
        forceUpdate: json['force_update'] as bool? ?? false,
        minVersion: json['min_version'] as String? ?? '0.0.0',
      );
}

class AppUpdateState {
  final bool checking;
  final bool updateAvailable;
  final AppUpdateInfo? info;
  final String? error;

  const AppUpdateState({
    this.checking = false,
    this.updateAvailable = false,
    this.info,
    this.error,
  });

  AppUpdateState copyWith({
    bool? checking,
    bool? updateAvailable,
    AppUpdateInfo? info,
    String? error,
  }) =>
      AppUpdateState(
        checking: checking ?? this.checking,
        updateAvailable: updateAvailable ?? this.updateAvailable,
        info: info ?? this.info,
        error: error ?? this.error,
      );
}

class AppUpdateNotifier extends Notifier<AppUpdateState> {
  @override
  AppUpdateState build() => const AppUpdateState();

  /// Compare two semver strings. Returns true if remote > local.
  bool _isNewer(String remote, String local) {
    final rParts = remote.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final lParts = local.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final l = i < lParts.length ? lParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }

  /// Check the backend for a newer version. Runs silently — never throws
  /// to the caller, swallows all errors (network down, 502, etc.).
  Future<void> checkForUpdate() async {
    state = state.copyWith(checking: true, error: null);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ));

      final response = await dio.get(ApiConstants.appVersion);
      final info = AppUpdateInfo.fromJson(response.data as Map<String, dynamic>);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "2.0.0"

      final hasUpdate = _isNewer(info.latestVersion, currentVersion);

      state = state.copyWith(
        checking: false,
        updateAvailable: hasUpdate,
        info: info,
      );

      if (hasUpdate) {
        debugPrint('[UPDATE] New version available: ${info.latestVersion} (current: $currentVersion)');
      } else {
        debugPrint('[UPDATE] App is up to date ($currentVersion)');
      }
    } catch (e) {
      debugPrint('[UPDATE] Check failed (silent): $e');
      state = state.copyWith(checking: false);
      // Silent — don't show error to user for background version check.
    }
  }

  /// Open the download URL in the browser so the user can install the update
  /// manually. Using REQUEST_INSTALL_PACKAGES to install APKs in-app is not
  /// allowed on the Play Store (restricted permission).
  Future<void> installUpdate() async {
    final url = state.info?.downloadUrl;
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[UPDATE] Open browser failed: $e');
    }
  }

  void dismiss() {
    state = const AppUpdateState();
  }
}

final appUpdateProvider =
    NotifierProvider<AppUpdateNotifier, AppUpdateState>(AppUpdateNotifier.new);
