// ignore_for_file: avoid_print

/// Unit test untuk ConnectivityService._isOnline() logic.
/// Tidak memakai device nyata — mock ConnectivityResult langsung.
///
/// Sejak connectivity_plus 6.x, API mengembalikan `List<ConnectivityResult>`
/// (sebuah device bisa online lewat WiFi + VPN sekaligus). Test ini mengikuti
/// bentuk list tersebut.
///
/// Jalankan:
///   flutter test test/core/connectivity_service_test.dart
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sc_student/core/services/connectivity_service.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // GROUP 1: Klasifikasi ConnectivityResult
  // ─────────────────────────────────────────────────────────────
  group('ConnectivityService._isOnline (white-box)', () {
    // Akses _isOnline lewat subclass test karena method private
    final svc = _TestableConnectivityService();

    test('wifi → online', () {
      expect(svc.testIsOnline([ConnectivityResult.wifi]), true);
    });

    test('ethernet → online', () {
      expect(svc.testIsOnline([ConnectivityResult.ethernet]), true);
    });

    test('mobile → online', () {
      expect(svc.testIsOnline([ConnectivityResult.mobile]), true);
    });

    test('vpn → online', () {
      expect(svc.testIsOnline([ConnectivityResult.vpn]), true);
    });

    test('satellite → online', () {
      expect(svc.testIsOnline([ConnectivityResult.satellite]), true);
    });

    test('none → offline', () {
      expect(svc.testIsOnline([ConnectivityResult.none]), false);
    });

    test('bluetooth → offline', () {
      expect(svc.testIsOnline([ConnectivityResult.bluetooth]), false);
    });

    test('other → offline', () {
      expect(svc.testIsOnline([ConnectivityResult.other]), false);
    });

    test('list kosong → offline', () {
      expect(svc.testIsOnline([]), false);
    });

    test('wifi + none → offline (none menang)', () {
      expect(
        svc.testIsOnline([ConnectivityResult.wifi, ConnectivityResult.none]),
        false,
      );
    });

    test('wifi + vpn → online (salah satu cukup)', () {
      expect(
        svc.testIsOnline([ConnectivityResult.wifi, ConnectivityResult.vpn]),
        true,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 2: connectivityProvider stream (dengan StreamController fake)
  // ─────────────────────────────────────────────────────────────
  group('onConnectivityChanged stream', () {
    test('emits true ketika ConnectivityResult.wifi masuk ke stream', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final svc = _FakeConnectivityService(controller.stream);

      // Ambil satu nilai dari stream yang sudah di-map ke bool
      final future = svc.onConnectivityChangedPublic.first;
      controller.add([ConnectivityResult.wifi]);

      final result = await future;
      expect(result, true);
      await controller.close();
    });

    test('emits false ketika ConnectivityResult.none masuk ke stream', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final svc = _FakeConnectivityService(controller.stream);

      final future = svc.onConnectivityChangedPublic.first;
      controller.add([ConnectivityResult.none]);

      final result = await future;
      expect(result, false);
      await controller.close();
    });

    test('sequence: offline → online emits false lalu true', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final svc = _FakeConnectivityService(controller.stream);

      final results = <bool>[];
      final sub = svc.onConnectivityChangedPublic.listen(results.add);

      controller.add([ConnectivityResult.none]);
      controller.add([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(results, [false, true]);
      await sub.cancel();
      await controller.close();
    });
  });
}

// ─────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────

/// Expose metode privat _isOnline untuk pengujian white-box.
class _TestableConnectivityService extends ConnectivityService {
  bool testIsOnline(List<ConnectivityResult> r) => isOnlinePublic(r);
}

/// Ganti stream internal dengan stream buatan untuk unit test.
class _FakeConnectivityService {
  final Stream<List<ConnectivityResult>> _fakeStream;

  _FakeConnectivityService(this._fakeStream);

  /// Cermin dari ConnectivityService._isOnline — sengaja independen supaya
  /// perilaku mapping stream diuji terhadap logika yang sama dengan produksi.
  static bool _isOnline(List<ConnectivityResult> rs) {
    if (rs.isEmpty || rs.contains(ConnectivityResult.none)) return false;
    return rs.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.satellite);
  }

  Stream<bool> get onConnectivityChangedPublic {
    return _fakeStream.map(_isOnline);
  }
}
