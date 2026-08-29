import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network status stream powered by connectivity_plus.
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService().onConnectivityChanged;
});

/// Watches WiFi/cellular and emits `true` when connected, `false` when not.
class ConnectivityService {
  final Connectivity _inner = Connectivity();

  /// Single-subscription stream: use a broadcast wrapper if multiple listeners needed.
  Stream<bool> get onConnectivityChanged {
    return _inner.onConnectivityChanged.asyncMap((result) async {
      // connectivity_plus v5: onConnectivityChanged emits a single ConnectivityResult.
      // Treat wifi/cellular/ethernet as online; none/vpn/bluetooth as offline.
      final hasConnection = _isOnline(result);
      debugPrint('[Connectivity] ${hasConnection ? "ONLINE" : "OFFLINE"} — $result');
      return hasConnection;
    });
  }

  /// One-shot check — use for polling or before starting a sync.
  Future<bool> check() async {
    final result = await _inner.checkConnectivity();
    return _isOnline(result);
  }

  bool _isOnline(ConnectivityResult r) {
    switch (r) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.mobile:
      case ConnectivityResult.vpn:
        return true;
      case ConnectivityResult.none:
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.other:
        return false;
    }
  }
}
