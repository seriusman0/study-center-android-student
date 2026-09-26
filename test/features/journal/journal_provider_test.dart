// ignore_for_file: avoid_print

/// Unit test untuk JournalNotifier — fokus pada offline queue dan sync.
/// Memakai mocktail untuk mock JournalRepository dan OfflineService.
///
/// Jalankan:
///   flutter test test/features/journal/journal_provider_test.dart
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sc_student/core/providers/journal_sync_signal.dart';
import 'package:sc_student/core/services/connectivity_service.dart';
import 'package:sc_student/core/services/offline_service.dart';
import 'package:sc_student/features/journal/models/journal_model.dart';
import 'package:sc_student/features/journal/providers/journal_provider.dart';
import 'package:sc_student/features/journal/repositories/journal_repository.dart';
import '../../helpers/offline_test_helper.dart';

// ── Mocks ──────────────────────────────────────────────────────
class MockJournalRepository extends Mock implements JournalRepository {}

// ── Fake data helpers ──────────────────────────────────────────
JournalSnapshot _fakeSnapshot({
  bool plChecked = false,
  bool pbChecked = false,
  bool verseChecked = false,
  String? verseRef,
  List<LifeItem>? lifeItems,
}) {
  return JournalSnapshot(
    date: '2024-09-01',
    bible: BibleReading(
      plPorsi: 'Kej 1',
      pbPorsi: 'Mat 1',
      plChecked: plChecked,
      pbChecked: pbChecked,
    ),
    verseRef: verseRef,
    verseChecked: verseChecked,
    lifeItems: lifeItems ??
        [
          const LifeItem(id: 1, kategori: 'kerohanian', label: 'Doa pagi', checked: false),
          const LifeItem(id: 2, kategori: 'pendidikan', label: 'Belajar', checked: false),
        ],
  );
}

// ── ProviderContainer builder ───────────────────────────────────
ProviderContainer _makeContainer({
  required JournalRepository repo,
  required OfflineService offline,
  required Stream<bool> connectivityStream,
}) {
  return ProviderContainer(
    overrides: [
      journalRepositoryProvider.overrideWithValue(repo),
      offlineServiceProvider.overrideWithValue(offline),
      connectivityProvider.overrideWith(
        (ref) => connectivityStream,
      ),
    ],
  );
}

void main() {
  setUpAll(initTestDatabase);

  late MockJournalRepository mockRepo;
  late OfflineService offlineSvc;

  setUp(() async {
    mockRepo = MockJournalRepository();
    offlineSvc = await makeTestOfflineService();

    // Default stub: today() berhasil, check() berhasil
    when(() => mockRepo.today(date: any(named: 'date')))
        .thenAnswer((_) async => _fakeSnapshot());
    when(() => mockRepo.check(
          itemType: any(named: 'itemType'),
          itemId: any(named: 'itemId'),
          checked: any(named: 'checked'),
          verseRef: any(named: 'verseRef'),
          date: any(named: 'date'),
        )).thenAnswer((_) async => _fakeSnapshot());
  });

  tearDown(() async {
    await offlineSvc.close();
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 1: Load basic
  // ─────────────────────────────────────────────────────────────
  group('JournalNotifier.load()', () {
    test('state loading=true saat load(), lalu false setelah selesai', () async {
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      final notifier = container.read(journalProvider.notifier);
      final loadFuture = notifier.load();

      // Tidak bisa cek loading=true secara sync karena await di dalam load()
      // Tapi pastikan selesai tanpa error:
      await loadFuture;

      expect(container.read(journalProvider).loading, false);
      expect(container.read(journalProvider).snapshot, isNotNull);
      expect(container.read(journalProvider).error, isNull);
    });

    test('error state saat repository throw', () async {
      when(() => mockRepo.today(date: any(named: 'date')))
          .thenThrow(Exception('Network error'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();

      final s = container.read(journalProvider);
      expect(s.error, isNotNull);
      expect(s.loading, false);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 2: Offline queue saat check gagal
  // ─────────────────────────────────────────────────────────────
  group('Offline queue — checkLife', () {
    test('checkLife enqueue ke queue saat network error', () async {
      // Load berhasil dulu
      when(() => mockRepo.today(date: any(named: 'date')))
          .thenAnswer((_) async => _fakeSnapshot());
      // check() gagal (offline)
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('No connection'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).checkLife(1, true);

      // Harus ada 1 item di queue
      expect(await offlineSvc.pendingCount(), 1);
      final ops = await offlineSvc.pending();
      expect(ops.first.kind, OfflineOpKind.checkLife);
      expect(ops.first.payload['item_id'], '1');
      expect(ops.first.payload['checked'], 'true');
    });

    test('checkLife optimistic update langsung ubah UI sebelum server reply', () async {
      // check() lambat / akan gagal — tapi UI harus sudah update
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Offline'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();

      // item id=1 awalnya unchecked
      final before = container.read(journalProvider).snapshot!.lifeItems
          .firstWhere((i) => i.id == 1);
      expect(before.checked, false);

      // checkLife → optimistic update → UI langsung checked=true
      await container.read(journalProvider.notifier).checkLife(1, true);

      final after = container.read(journalProvider).snapshot!.lifeItems
          .firstWhere((i) => i.id == 1);
      expect(after.checked, true);
    });
  });

  group('Offline queue — checkBible', () {
    test('checkBible enqueue saat network error', () async {
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Offline'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).checkBible('pl', true);

      final ops = await offlineSvc.pending();
      expect(ops.length, 1);
      expect(ops.first.kind, OfflineOpKind.checkBible);
      expect(ops.first.payload['item_type'], 'pl');
    });
  });

  group('Offline queue — saveVerseRef', () {
    test('saveVerseRef enqueue saat network error', () async {
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Offline'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).saveVerseRef('Yohanes 3:16');

      final ops = await offlineSvc.pending();
      expect(ops.length, 1);
      expect(ops.first.kind, OfflineOpKind.saveVerse);
      expect(ops.first.payload['verse_ref'], 'Yohanes 3:16');
    });
  });

  group('Offline queue — checkVerseChecked', () {
    test('checkVerseChecked enqueue saat network error', () async {
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Offline'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).checkVerseChecked(true);

      final ops = await offlineSvc.pending();
      expect(ops.length, 1);
      expect(ops.first.kind, OfflineOpKind.checkVerseCheck);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 3: syncPending
  // ─────────────────────────────────────────────────────────────
  group('syncPending()', () {
    test('syncPending() memproses semua operasi yang pending dan mengosongkan queue', () async {
      // Pre-populate queue dengan 2 operasi
      await offlineSvc.enqueue(OfflineOpKind.checkLife, {
        'item_id': '1',
        'checked': 'true',
        'date': '2024-09-01',
      });
      await offlineSvc.enqueue(OfflineOpKind.checkBible, {
        'item_type': 'pl',
        'checked': 'true',
        'date': '2024-09-01',
      });

      // check() berhasil saat sync
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => _fakeSnapshot());

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      // Load terlebih dahulu agar snapshot tidak null
      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).syncPending();

      // Queue harus kosong
      expect(await offlineSvc.pendingCount(), 0);
    });

    test('syncPending() memanggil repository.check() untuk setiap operasi pending', () async {
      await offlineSvc.enqueue(OfflineOpKind.checkLife, {
        'item_id': '2',
        'checked': 'false',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => _fakeSnapshot());

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).syncPending();

      // check() dipanggil 2x: 1 untuk load (tidak — sebenarnya check() dipanggil dari syncPending untuk life)
      // Verifikasi check dipanggil setidaknya 1x untuk operasi queue
      verify(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).called(greaterThanOrEqualTo(1));
    });

    test('syncPending() retry gagal → operasi tetap di queue dengan retry_count naik', () async {
      await offlineSvc.enqueue(OfflineOpKind.checkLife, {
        'item_id': '1',
        'checked': 'true',
        'date': '2024-09-01',
      });

      // check() gagal saat sync
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Still offline'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).syncPending();

      // Operasi masih ada (retry_count baru 1, belum melebihi maxRetries=3)
      expect(await offlineSvc.pendingCount(), 1);
      final ops = await offlineSvc.pending();
      expect(ops.first.retryCount, 1);
    });

    test('syncPending() menghapus operasi setelah melebihi 3 retry', () async {
      // Langsung set retry_count = 3 (sudah di limit)
      final id = await offlineSvc.enqueue(OfflineOpKind.checkLife, {
        'item_id': '1',
        'checked': 'true',
        'date': '2024-09-01',
      });
      // Set retry 2x dulu agar saat sync retry ke-3 → exceeded
      await offlineSvc.markRetry(id, 0); // → 1
      await offlineSvc.markRetry(id, 1); // → 2
      await offlineSvc.markRetry(id, 2); // → 3 (masih ada)

      // check() gagal lagi
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Still offline'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).syncPending();

      // Operasi harus dihapus setelah exceeded
      expect(await offlineSvc.pendingCount(), 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 4: Auto-sync saat online
  // ─────────────────────────────────────────────────────────────
  group('Auto-sync ketika connectivity restored', () {
    test('syncPending() terpanggil saat stream connectivity berubah ke true', () async {
      // Pre-populate queue
      await offlineSvc.enqueue(OfflineOpKind.checkLife, {
        'item_id': '1',
        'checked': 'true',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => _fakeSnapshot());

      final connectivityController = StreamController<bool>.broadcast();

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: connectivityController.stream,
      );
      addTearDown(container.dispose);
      addTearDown(connectivityController.close);

      // Inisialisasi provider
      container.read(journalProvider);
      await container.read(journalProvider.notifier).load();

      // Simulasi jaringan kembali online
      connectivityController.add(true);
      // Beri waktu listener async berjalan
      await Future.delayed(const Duration(milliseconds: 100));

      // Queue harus kosong setelah auto-sync
      expect(await offlineSvc.pendingCount(), 0);
    });

    test('journalSyncSignalProvider trigger syncPending() saat di-increment', () async {
      await offlineSvc.enqueue(OfflineOpKind.checkBible, {
        'item_type': 'pb',
        'checked': 'true',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => _fakeSnapshot());

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      container.read(journalProvider);
      await container.read(journalProvider.notifier).load();

      // Trigger sync signal (simulasi dari bagian lain app)
      container.read(journalSyncSignalProvider.notifier).state++;
      await Future.delayed(const Duration(milliseconds: 100));

      expect(await offlineSvc.pendingCount(), 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 5: pendingOfflineOps state
  // ─────────────────────────────────────────────────────────────
  group('pendingOfflineOps state', () {
    test('pendingOfflineOps bertambah saat checkLife enqueue', () async {
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Offline'));

      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();

      expect(container.read(journalProvider).pendingOfflineOps, 0);
      await container.read(journalProvider.notifier).checkLife(1, true);
      expect(container.read(journalProvider).pendingOfflineOps, 1);
    });
  });
}
