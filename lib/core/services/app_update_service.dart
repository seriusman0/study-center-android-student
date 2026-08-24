import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  final bool downloading;
  final double downloadProgress; // 0.0 – 1.0
  final bool updateAvailable;
  final bool downloadComplete;
  final AppUpdateInfo? info;
  final String? error;
  final String? apkPath;

  const AppUpdateState({
    this.checking = false,
    this.downloading = false,
    this.downloadProgress = 0,
    this.updateAvailable = false,
    this.downloadComplete = false,
    this.info,
    this.error,
    this.apkPath,
  });

  AppUpdateState copyWith({
    bool? checking,
    bool? downloading,
    double? downloadProgress,
    bool? updateAvailable,
    bool? downloadComplete,
    AppUpdateInfo? info,
    String? error,
    String? apkPath,
  }) =>
      AppUpdateState(
        checking: checking ?? this.checking,
        downloading: downloading ?? this.downloading,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        updateAvailable: updateAvailable ?? this.updateAvailable,
        downloadComplete: downloadComplete ?? this.downloadComplete,
        info: info ?? this.info,
        error: error ?? this.error,
        apkPath: apkPath ?? this.apkPath,
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
        // Start background download automatically.
        await downloadUpdate();
      } else {
        debugPrint('[UPDATE] App is up to date ($currentVersion)');
      }
    } catch (e) {
      debugPrint('[UPDATE] Check failed (silent): $e');
      state = state.copyWith(checking: false);
      // Silent — don't show error to user for background version check.
    }
  }

  /// Download the APK in the background. Shows progress via state.
  Future<void> downloadUpdate() async {
    final info = state.info;
    if (info == null || info.downloadUrl.isEmpty) return;

    state = state.copyWith(downloading: true, downloadProgress: 0);

    try {
      final dir = await getTemporaryDirectory();
      final apkPath = '${dir.path}/study-center-nias-${info.latestVersion}.apk';
      final file = File(apkPath);

      // Skip download if already downloaded.
      if (file.existsSync()) {
        debugPrint('[UPDATE] APK already downloaded at $apkPath');
        state = state.copyWith(
          downloading: false,
          downloadComplete: true,
          apkPath: apkPath,
        );
        return;
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
      ));

      await dio.download(
        info.downloadUrl,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(
              downloadProgress: received / total,
            );
          }
        },
      );

      debugPrint('[UPDATE] APK downloaded to $apkPath');
      state = state.copyWith(
        downloading: false,
        downloadComplete: true,
        apkPath: apkPath,
      );
    } catch (e) {
      debugPrint('[UPDATE] Download failed: $e');
      state = state.copyWith(
        downloading: false,
        error: 'Gagal mengunduh pembaruan.',
      );
    }
  }

  /// Open the downloaded APK for installation.
  Future<void> installUpdate() async {
    final path = state.apkPath;
    if (path == null) return;
    try {
      await OpenFilex.open(path, type: 'application/vnd.android.package-archive');
    } catch (e) {
      debugPrint('[UPDATE] Install trigger failed: $e');
    }
  }

  void dismiss() {
    state = const AppUpdateState();
  }
}

final appUpdateProvider =
    NotifierProvider<AppUpdateNotifier, AppUpdateState>(AppUpdateNotifier.new);
