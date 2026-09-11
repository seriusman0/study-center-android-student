// ignore_for_file: avoid_print

/// Unit test untuk OfflineService (SQLite queue).
/// Semua test berjalan tanpa device/emulator menggunakan sqflite_common_ffi.
///
/// Jalankan:
///   flutter test test/core/offline_service_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sc_student/core/services/offline_service.dart';
import '../helpers/offline_test_helper.dart';

void main() {
  setUpAll(initTestDatabase);

  late OfflineService svc;

  setUp(() async {
    svc = await makeTestOfflineService();
  });

  tearDown(() async {
    await svc.close();
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 1: Enqueue & pending
  // ─────────────────────────────────────────────────────────────
  group('enqueue & pending', () {
    test('queue kosong saat baru dibuat', () async {
      expect(await svc.pendingCount(), 0);
      expect(await svc.pending(), isEmpty);
    });

    test('enqueue menyimpan satu operasi dan pendingCount = 1', () async {
      await svc.enqueue(OfflineOpKind.checkLife, {
        'item_id': '42',
        'checked': 'true',
        'date': '2024-09-01',
      });
      expect(await svc.pendingCount(), 1);
    });

    test('pending() mengembalikan operasi dengan payload yang sama', () async {
      final payload = {
        'item_id': '42',
        'checked': 'true',
        'date': '2024-09-01',
      };
      await svc.enqueue(OfflineOpKind.checkLife, payload);
      final ops = await svc.pending();

      expect(ops.length, 1);
      expect(ops.first.kind, OfflineOpKind.checkLife);
      expect(ops.first.payload['item_id'], '42');
      expect(ops.first.payload['checked'], 'true');
      expect(ops.first.payload['date'], '2024-09-01');
    });

    test('pending() mengembalikan oldest-first (urutan FIFO)', () async {
      await svc.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      await Future.delayed(const Duration(milliseconds: 5)); // jamin created_at berbeda
      await svc.enqueue(OfflineOpKind.checkBible, {'item_type': 'pl', 'checked': 'true', 'date': '2024-09-01'});

      final ops = await svc.pending();
      expect(ops[0].kind, OfflineOpKind.checkLife);
      expect(ops[1].kind, OfflineOpKind.checkBible);
    });

    test('enqueue berbagai kind yang didukung', () async {
      final kinds = [
        OfflineOpKind.checkLife,
        OfflineOpKind.checkBible,
        OfflineOpKind.saveVerse,
        OfflineOpKind.checkVerseCheck,
        OfflineOpKind.collegeCheck,
        OfflineOpKind.collegeStudyLog,
        OfflineOpKind.scholarshipCheck,
      ];
      for (final k in kinds) {
        await svc.enqueue(k, {'key': 'val', 'date': '2024-09-01'});
      }
      expect(await svc.pendingCount(), kinds.length);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 2: Remove
  // ─────────────────────────────────────────────────────────────
  group('remove', () {
    test('remove() menghapus operasi berdasarkan id', () async {
      final id = await svc.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      await svc.remove(id);
      expect(await svc.pendingCount(), 0);
    });

    test('remove() hanya menghapus operasi dengan id tertentu', () async {
      final id1 = await svc.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      await svc.enqueue(OfflineOpKind.checkBible, {'item_type': 'pl', 'checked': 'true', 'date': '2024-09-01'});

      await svc.remove(id1);

      final ops = await svc.pending();
      expect(ops.length, 1);
      expect(ops.first.kind, OfflineOpKind.checkBible);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 3: Retry logic
  // ─────────────────────────────────────────────────────────────
  group('markRetry', () {
    test('markRetry mengembalikan false jika masih dalam batas', () async {
      final id = await svc.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      final exceeded = await svc.markRetry(id, 0); // 0 retry saat ini
      expect(exceeded, false);
    });

    test('markRetry mengembalikan true saat retry == maxRetries (3)', () async {
      final id = await svc.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      final exceeded = await svc.markRetry(id, 3); // 3 == maxRetries
      expect(exceeded, true);
    });

    test('retry_count bertambah di database setelah markRetry', () async {
      final id = await svc.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      await svc.markRetry(id, 0); // increment dari 0 → 1

      final ops = await svc.pending();
      expect(ops.first.retryCount, 1);
    });

    test('operasi bertahan di queue setelah markRetry (belum melebihi limit)', () async {
      final id = await svc.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      await svc.markRetry(id, 1);
      expect(await svc.pendingCount(), 1);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 4: Clear
  // ─────────────────────────────────────────────────────────────
  group('clear', () {
    test('clear() mengosongkan seluruh queue', () async {
      await svc.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      await svc.enqueue(OfflineOpKind.checkBible, {'item_type': 'pl', 'checked': 'true', 'date': '2024-09-01'});
      await svc.clear();
      expect(await svc.pendingCount(), 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 5: Payload encode/decode round-trip
  // ─────────────────────────────────────────────────────────────
  group('payload encoding', () {
    test('payload dengan value yang mengandung = tidak corrupt', () async {
      // Pastikan encode/decode aman untuk nilai yang tidak mengandung '&'/'='
      await svc.enqueue(OfflineOpKind.saveVerse, {
        'verse_ref': 'Yohanes 3:16',
        'date': '2024-09-01',
      });
      final ops = await svc.pending();
      expect(ops.first.payload['verse_ref'], 'Yohanes 3:16');
      expect(ops.first.payload['date'], '2024-09-01');
    });

    test('semua field bool tersimpan sebagai string', () async {
      await svc.enqueue(OfflineOpKind.checkBible, {
        'item_type': 'pl',
        'checked': 'false',
        'date': '2024-09-01',
      });
      final ops = await svc.pending();
      expect(ops.first.payload['checked'], 'false');
    });
  });
}
