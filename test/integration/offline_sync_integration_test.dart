// ignore_for_file: avoid_print

/// Integration test: full offline → sync flow lintas tiga provider.
///
/// Test ini mensimulasikan skenario nyata:
///   1. User pakai app saat offline — semua operasi masuk queue
///   2. Koneksi kembali → auto-sync → backend dipanggil → queue kosong
///   3. Queue dibersihkan saat logout
///
/// Jalankan:
///   flutter test test/integration/offline_sync_integration_test.dart
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sc_student/core/services/connectivity_service.dart';
import 'package:sc_student/core/services/offline_service.dart';
import 'package:sc_student/features/college/models/college_journal_model.dart';
import 'package:sc_student/features/college/providers/college_journal_provider.dart';
import 'package:sc_student/features/college/repositories/college_repository.dart';
import 'package:sc_student/features/journal/models/journal_model.dart';
import 'package:sc_student/features/journal/providers/journal_provider.dart';
import 'package:sc_student/features/journal/repositories/journal_repository.dart';
import 'package:sc_student/features/scholarship_teenager/providers/scholarship_teenager_journal_provider.dart';
import 'package:sc_student/features/scholarship_teenager/repositories/scholarship_teenager_journal_repository.dart';
import '../helpers/offline_test_helper.dart';

// ── Mocks ──────────────────────────────────────────────────────
class MockJournalRepository extends Mock implements JournalRepository {}
class MockCollegeJournalRepository extends Mock implements CollegeJournalRepository {}
class MockScholarshipRepo extends Mock implements ScholarshipTeenagerJournalRepository {}

// ── Fake data ──────────────────────────────────────────────────
JournalSnapshot _fakeJournalSnapshot() => JournalSnapshot(
      date: '2024-09-01',
      bible: const BibleReading(
        plPorsi: 'Kej 1', pbPorsi: 'Mat 1', plChecked: false, pbChecked: false,
      ),
      lifeItems: const [
        LifeItem(id: 1, kategori: 'kerohanian', label: 'Doa', checked: false),
      ],
    );

CollegeJournalSnapshot _fakeCollegeSnapshot() =>
    CollegeJournalSnapshot.fromJson({
      'date': '2024-09-01',
      'bible': {'day_no': 1, 'pl_porsi': 'Kej 1', 'pb_porsi': 'Mat 1', 'pl_checked': false, 'pb_checked': false},
      'life_items': [
        {'id': 10, 'kategori': 'kerohanian', 'label': 'Doa', 'response_type': 'check', 'checked': false},
      ],
      'study_logs': [],
      'config': {},
    });

void main() {
  setUpAll(initTestDatabase);

  late MockJournalRepository mockJournalRepo;
  late MockCollegeJournalRepository mockCollegeRepo;
  late MockScholarshipRepo mockScholarshipRepo;
  late OfflineService sharedOffline;
  late StreamController<bool> connectivityCtrl;

  setUp(() async {
    mockJournalRepo = MockJournalRepository();
    mockCollegeRepo = MockCollegeJournalRepository();
    mockScholarshipRepo = MockScholarshipRepo();
    sharedOffline = await makeTestOfflineService();
    connectivityCtrl = StreamController<bool>.broadcast();

    // Default: today() berhasil untuk semua
    when(() => mockJournalRepo.today(date: any(named: 'date')))
        .thenAnswer((_) async => _fakeJournalSnapshot());
    when(() => mockCollegeRepo.today(date: any(named: 'date')))
        .thenAnswer((_) async => _fakeCollegeSnapshot());
    when(() => mockCollegeRepo.profile()).thenAnswer((_) async => null);
    when(() => mockScholarshipRepo.today(date: any(named: 'date')))
        .thenAnswer((_) async => _fakeCollegeSnapshot());
  });

  tearDown(() async {
    await sharedOffline.close();
    await connectivityCtrl.close();
  });

  ProviderContainer _makeContainer() => ProviderContainer(
        overrides: [
          journalRepositoryProvider.overrideWithValue(mockJournalRepo),
          collegeJournalRepositoryProvider.overrideWithValue(mockCollegeRepo),
          scholarshipTeenagerJournalRepositoryProvider.overrideWithValue(mockScholarshipRepo),
          offlineServiceProvider.overrideWithValue(sharedOffline),
          connectivityProvider.overrideWith((ref) => connectivityCtrl.stream),
        ],
      );

  // ─────────────────────────────────────────────────────────────
  // SCENARIO 1: Multi-provider offline accumulation
  // ─────────────────────────────────────────────────────────────
  group('Scenario 1: Akumulasi offline dari berbagai provider', () {
    test('Queue menampung operasi dari journal + college + scholarship', () async {
      // Semua check() gagal (offline)
      when(() => mockJournalRepo.check(
            itemType: any(named: 'itemType'), itemId: any(named: 'itemId'),
            checked: any(named: 'checked'), verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Offline'));
      when(() => mockCollegeRepo.check(
            itemId: any(named: 'itemId'), itemType: any(named: 'itemType'),
            checked: any(named: 'checked'), date: any(named: 'date'),
            jamMulai: any(named: 'jamMulai'), jamSelesai: any(named: 'jamSelesai'),
            tipe: any(named: 'tipe'),
          )).thenThrow(Exception('Offline'));
      when(() => mockScholarshipRepo.check(
            itemType: any(named: 'itemType'), itemId: any(named: 'itemId'),
            checked: any(named: 'checked'), date: any(named: 'date'),
            verseRef: any(named: 'verseRef'),
          )).thenThrow(Exception('Offline'));

      final container = _makeContainer();
      addTearDown(container.dispose);

      // Load semua provider
      await container.read(journalProvider.notifier).load();
      await container.read(collegeJournalProvider.notifier).load();
      await container.read(scholarshipTeenagerJournalProvider.notifier).load();

      // Trigger operasi dari masing-masing
      await container.read(journalProvider.notifier).checkLife(1, true);
      await container.read(collegeJournalProvider.notifier).checkBible('pl', true);
      await container.read(scholarshipTeenagerJournalProvider.notifier).checkBible('pb', false);

      // Queue harus menampung 3 operasi berbeda
      expect(await sharedOffline.pendingCount(), 3);

      final ops = await sharedOffline.pending();
      final kinds = ops.map((o) => o.kind).toSet();
      expect(kinds, containsAll([
        OfflineOpKind.checkLife,
        OfflineOpKind.collegeCheck,
        OfflineOpKind.scholarshipCheck,
      ]));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // SCENARIO 2: Full offline → online sync cycle
  // ─────────────────────────────────────────────────────────────
  group('Scenario 2: Offline → jaringan pulih → auto-sync sukses', () {
    test('Queue kosong setelah koneksi kembali dan semua ops sukses', () async {
      // Phase 1: offline — enqueue 2 operasi langsung
      await sharedOffline.enqueue(OfflineOpKind.checkLife, {
        'item_id': '1', 'checked': 'true', 'date': '2024-09-01',
      });
      await sharedOffline.enqueue(OfflineOpKind.checkBible, {
        'item_type': 'pl', 'checked': 'true', 'date': '2024-09-01',
      });

      expect(await sharedOffline.pendingCount(), 2);

      // Phase 2: check() akan berhasil saat sync
      when(() => mockJournalRepo.check(
            itemType: any(named: 'itemType'), itemId: any(named: 'itemId'),
            checked: any(named: 'checked'), verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => _fakeJournalSnapshot());

      final container = _makeContainer();
      addTearDown(container.dispose);

      // Load journal provider dulu agar snapshot ada
      await container.read(journalProvider.notifier).load();

      // Phase 3: simulasi jaringan kembali
      connectivityCtrl.add(true);
      await Future.delayed(const Duration(milliseconds: 200));

      // Queue harus kosong
      expect(await sharedOffline.pendingCount(), 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // SCENARIO 3: Partial failure — sebagian sync sukses, sebagian gagal
  // ─────────────────────────────────────────────────────────────
  group('Scenario 3: Partial sync — sukses + gagal dalam batch yang sama', () {
    test('Operasi sukses dihapus, operasi gagal tetap dengan retry_count naik', () async {
      // Enqueue 2 operasi: satu akan sukses (checkLife), satu akan gagal (checkBible)
      await sharedOffline.enqueue(OfflineOpKind.checkLife, {
        'item_id': '1', 'checked': 'true', 'date': '2024-09-01',
      });
      await sharedOffline.enqueue(OfflineOpKind.checkBible, {
        'item_type': 'pl', 'checked': 'true', 'date': '2024-09-01',
      });

      var callCount = 0;
      when(() => mockJournalRepo.check(
            itemType: any(named: 'itemType'), itemId: any(named: 'itemId'),
            checked: any(named: 'checked'), verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return _fakeJournalSnapshot(); // checkLife sukses
        throw Exception('Server error'); // checkBible gagal
      });

      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).syncPending();

      // Hanya 1 operasi tersisa (checkBible yang gagal)
      expect(await sharedOffline.pendingCount(), 1);
      final remaining = await sharedOffline.pending();
      expect(remaining.first.kind, OfflineOpKind.checkBible);
      expect(remaining.first.retryCount, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // SCENARIO 4: Clear setelah logout
  // ─────────────────────────────────────────────────────────────
  group('Scenario 4: Logout membersihkan queue', () {
    test('Queue kosong setelah clear() dipanggil (simulasi logout)', () async {
      // Isi queue dulu
      await sharedOffline.enqueue(OfflineOpKind.checkLife, {'item_id': '1', 'checked': 'true', 'date': '2024-09-01'});
      await sharedOffline.enqueue(OfflineOpKind.checkBible, {'item_type': 'pl', 'checked': 'true', 'date': '2024-09-01'});
      await sharedOffline.enqueue(OfflineOpKind.scholarshipCheck, {'item_type': 'pb', 'checked': 'false', 'date': '2024-09-01'});

      expect(await sharedOffline.pendingCount(), 3);

      // Logout → clear
      await sharedOffline.clear();

      expect(await sharedOffline.pendingCount(), 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // SCENARIO 5: Max retry — operasi dibuang setelah 3x gagal
  // ─────────────────────────────────────────────────────────────
  group('Scenario 5: Max retry exceeded — operasi dibuang otomatis', () {
    test('Operasi dengan retryCount=3 dibuang saat syncPending berikutnya', () async {
      final id = await sharedOffline.enqueue(OfflineOpKind.checkLife, {
        'item_id': '1', 'checked': 'true', 'date': '2024-09-01',
      });
      // Simulasi sudah 3x retry
      await sharedOffline.markRetry(id, 0); // → 1
      await sharedOffline.markRetry(id, 1); // → 2
      await sharedOffline.markRetry(id, 2); // → 3

      // check() masih gagal
      when(() => mockJournalRepo.check(
            itemType: any(named: 'itemType'), itemId: any(named: 'itemId'),
            checked: any(named: 'checked'), verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenThrow(Exception('Permanent error'));

      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).syncPending();

      // Operasi dibuang karena exceeded max retries
      expect(await sharedOffline.pendingCount(), 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // SCENARIO 6: FIFO order — operasi diproses sesuai urutan masuk
  // ─────────────────────────────────────────────────────────────
  group('Scenario 6: FIFO ordering dalam sync', () {
    test('Operasi diproses dalam urutan masuk (oldest-first)', () async {
      final processed = <String>[];

      // Enqueue dalam urutan tertentu
      await sharedOffline.enqueue(OfflineOpKind.checkLife, {
        'item_id': '1', 'checked': 'true', 'date': '2024-09-01',
      });
      await Future.delayed(const Duration(milliseconds: 5));
      await sharedOffline.enqueue(OfflineOpKind.checkBible, {
        'item_type': 'pl', 'checked': 'true', 'date': '2024-09-01',
      });
      await Future.delayed(const Duration(milliseconds: 5));
      await sharedOffline.enqueue(OfflineOpKind.checkVerseCheck, {
        'checked': 'true', 'date': '2024-09-01',
      });

      when(() => mockJournalRepo.check(
            itemType: any(named: 'itemType'), itemId: any(named: 'itemId'),
            checked: any(named: 'checked'), verseRef: any(named: 'verseRef'),
            date: any(named: 'date'),
          )).thenAnswer((invocation) async {
        final type = invocation.namedArguments[#itemType] as String?;
        processed.add(type ?? 'unknown');
        return _fakeJournalSnapshot();
      });

      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(journalProvider.notifier).load();
      await container.read(journalProvider.notifier).syncPending();

      // Harus diproses berurutan: life (item_type='life'), pl, verse_check
      expect(processed.length, 3);
      expect(processed[0], 'life');
      expect(processed[1], 'pl');
      expect(processed[2], 'verse_check');
      expect(await sharedOffline.pendingCount(), 0);
    });
  });
}
