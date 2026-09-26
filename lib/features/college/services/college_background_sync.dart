import 'package:flutter/foundation.dart';

/// College background sync is handled reactively via [ConnectivityService]
/// in the foreground (syncPending runs whenever the network is restored).
/// This is a no-op shim retained so existing imports continue to resolve
/// without pulling in the `workmanager` plugin (which is incompatible with
/// current Flutter embedding on debug builds).
class CollegeBackgroundSync {
  /// Previously registered a 15-minute Workmanager task. Now a no-op —
  /// connectivity-driven sync in journal_provider.dart handles it.
  static Future<void> initialize() async {
    debugPrint('[CollegeBackgroundSync] No-op initialize (connectivity-driven sync active)');
  }

  /// Cancel background sync (no-op).
  static Future<void> cancel() async {
    debugPrint('[CollegeBackgroundSync] No-op cancel');
  }
}
