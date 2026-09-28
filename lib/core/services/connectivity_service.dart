import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network status stream powered by connectivity_plus.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final svc = ConnectivityService();
  yield await svc.check();
  yield* svc.onConnectivityChanged;
});

/// Watches WiFi/cellular and emits `true` when connected, `false` when not.
class ConnectivityService {
  final Connectivity _inner = Connectivity();

  /// Single-subscription stream: use a broadcast wrapper if multiple listeners needed.
  Stream<bool> get onConnectivityChanged {
    return _inner.onConnectivityChanged.asyncMap((results) async {
      final hasConnection = _isOnline(results);
      debugPrint('[Connectivity] ${hasConnection ? "ONLINE" : "OFFLINE"} — $results');
      return hasConnection;
    });
  }

  /// One-shot check — use for polling or before starting a sync.
  Future<bool> check() async {
    final results = await _inner.checkConnectivity();
    return _isOnline(results);
  }

  bool _isOnline(List<ConnectivityResult> rs) {
    if (rs.isEmpty || rs.contains(ConnectivityResult.none)) {
      return false;
    }
    return rs.any((r) => 
        r == ConnectivityResult.wifi || 
        r == ConnectivityResult.ethernet || 
        r == ConnectivityResult.mobile || 
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.satellite);
  }

  @visibleForTesting
  bool isOnlinePublic(List<ConnectivityResult> r) => _isOnline(r);
}

