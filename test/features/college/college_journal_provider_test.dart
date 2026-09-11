// ignore_for_file: avoid_print

/// Unit test untuk CollegeJournalNotifier — offline queue dan sync.
///
/// Jalankan:
///   flutter test test/features/college/college_journal_provider_test.dart
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sc_student/core/services/connectivity_service.dart';
import 'package:sc_student/core/services/offline_service.dart';
import 'package:sc_student/features/college/models/college_journal_model.dart';
import 'package:sc_student/features/college/models/college_profile_model.dart';
import 'package:sc_student/features/college/providers/college_journal_provider.dart';
import 'package:sc_student/features/college/repositories/college_repository.dart';
import '../../helpers/offline_test_helper.dart';

// ── Mocks ──────────────────────────────────────────────────────
class MockCollegeJournalRepository extends Mock
    implements CollegeJournalRepository {}

// ── Fake helpers ───────────────────────────────────────────────
CollegeJournalSnapshot _fakeCollegeSnapshot() {
  return CollegeJournalSnapshot.fromJson({
    'date': '2024-09-01',
    'bible': {
      'day_no': 1,
      'pl_porsi': 'Kej 1',
      'pb_porsi': 'Mat 1',
      'pl_checked': false,
      'pb_checked': false,
    },
    'life_items': [
      {'id': 10, 'kategori': 'kerohanian', 'label': 'Doa pagi', 'response_type': 'check', 'checked': false},
      {'id': 11, 'kategori': 'pendidikan', 'label': 'Belajar', 'response_type': 'boolean', 'checked': false},
    ],
    'study_logs': [],
    'config': {},
  });
}

const _fakeProfile = CollegeProfile(institutionName: 'Test U', position: 'Mahasiswa');

// ── Container builder ───────────────────────────────────────────
ProviderContainer _makeContainer({
  required CollegeJournalRepository repo,
  required OfflineService offline,
  required Stream<bool> connectivityStream,
}) {
  return ProviderContainer(
    overrides: [
      collegeJournalRepositoryProvider.overrideWithValue(repo),
      offlineServiceProvider.overrideWithValue(offline),
      connectivityProvider.overrideWith((ref) => connectivityStream),
    ],
  );
}

void main() {
  setUpAll(initTestDatabase);

  late MockCollegeJournalRepository mockRepo;
  late OfflineService offlineSvc;

  setUp(() async {
    mockRepo = MockCollegeJournalRepository();
    offlineSvc = await makeTestOfflineService();

    when(() => mockRepo.today(date: any(named: 'date')))
        .thenAnswer((_) async => _fakeCollegeSnapshot());
    when(() => mockRepo.profile())
        .thenAnswer((_) async => _fakeProfile);
    when(() => mockRepo.check(
          itemId: any(named: 'itemId'),
          itemType: any(named: 'itemType'),
          checked: any(named: 'checked'),
          date: any(named: 'date'),
          jamMulai: any(named: 'jamMulai'),
          jamSelesai: any(named: 'jamSelesai'),
          tipe: any(named: 'tipe'),
        )).thenAnswer((_) async => _fakeCollegeSnapshot());
  });

  tearDown(() async {
    await offlineSvc.close();
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 1: Load
  // ─────────────────────────────────────────────────────────────
  group('CollegeJournalNotifier.load()', () {
    test('load berhasil mengisi snapshot', () async {
      // Gunakan StreamController yang tidak langsung ditutup agar dispose aman
      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(() async {
        container.dispose();
        await ctrl.close();
      });

      await container.read(collegeJournalProvider.notifier).load();

      final s = container.read(collegeJournalProvider);
      expect(s.snapshot, isNotNull);
      expect(s.loading, false);
      expect(s.error, isNull);
    });

    test('load error mengisi state.error', () async {
      when(() => mockRepo.today(date: any(named: 'date')))
          .thenThrow(Exception('Gagal'));

      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(() async {
        container.dispose();
        await ctrl.close();
      });

      await container.read(collegeJournalProvider.notifier).load();

      expect(container.read(collegeJournalProvider).error, isNotNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 2: Offline queue — checkBible
  // ─────────────────────────────────────────────────────────────
  group('Offline queue — checkBible', () {
    test('checkBible("pl") enqueue saat network error', () async {
      when(() => mockRepo.check(
            itemId: any(named: 'itemId'),
            itemType: any(named: 'itemType'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            jamMulai: any(named: 'jamMulai'),
            jamSelesai: any(named: 'jamSelesai'),
            tipe: any(named: 'tipe'),
          )).thenThrow(Exception('Offline'));

      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(() async {
        container.dispose();
        await ctrl.close();
      });

      await container.read(collegeJournalProvider.notifier).load();
      await container.read(collegeJournalProvider.notifier).checkBible('pl', true);

      expect(await offlineSvc.pendingCount(), 1);
      final ops = await offlineSvc.pending();
      expect(ops.first.kind, OfflineOpKind.collegeCheck);
      expect(ops.first.payload['item_type'], 'pl');
      expect(ops.first.payload['checked'], 'true');
    });

    test('checkBible("pb") enqueue saat network error', () async {
      when(() => mockRepo.check(
            itemId: any(named: 'itemId'),
            itemType: any(named: 'itemType'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            jamMulai: any(named: 'jamMulai'),
            jamSelesai: any(named: 'jamSelesai'),
            tipe: any(named: 'tipe'),
          )).thenThrow(Exception('Offline'));

      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(() async {
        container.dispose();
        await ctrl.close();
      });

      await container.read(collegeJournalProvider.notifier).load();
      await container.read(collegeJournalProvider.notifier).checkBible('pb', false);

      final ops = await offlineSvc.pending();
      expect(ops.first.payload['item_type'], 'pb');
      expect(ops.first.payload['checked'], 'false');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 3: Offline queue — checkLife
  // ─────────────────────────────────────────────────────────────
  group('Offline queue — checkLife', () {
    test('checkLife enqueue saat offline', () async {
      when(() => mockRepo.check(
            itemId: any(named: 'itemId'),
            itemType: any(named: 'itemType'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            jamMulai: any(named: 'jamMulai'),
            jamSelesai: any(named: 'jamSelesai'),
            tipe: any(named: 'tipe'),
          )).thenThrow(Exception('Offline'));

      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(() async {
        container.dispose();
        await ctrl.close();
      });

      await container.read(collegeJournalProvider.notifier).load();
      await container.read(collegeJournalProvider.notifier).checkLife(10, true);

      final ops = await offlineSvc.pending();
      expect(ops.first.kind, OfflineOpKind.collegeCheck);
      expect(ops.first.payload['item_id'], '10');
      expect(ops.first.payload['checked'], 'true');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 4: syncPending
  // ─────────────────────────────────────────────────────────────
  group('syncPending()', () {
    test('memproses collegeCheck dan mengosongkan queue', () async {
      await offlineSvc.enqueue(OfflineOpKind.collegeCheck, {
        'item_type': 'pl',
        'checked': 'true',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemId: any(named: 'itemId'),
            itemType: any(named: 'itemType'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            jamMulai: any(named: 'jamMulai'),
            jamSelesai: any(named: 'jamSelesai'),
            tipe: any(named: 'tipe'),
          )).thenAnswer((_) async => _fakeCollegeSnapshot());

      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(() async {
        container.dispose();
        await ctrl.close();
      });

      await container.read(collegeJournalProvider.notifier).load();
      await container.read(collegeJournalProvider.notifier).syncPending();

      expect(await offlineSvc.pendingCount(), 0);
    });

    test('retry gagal → operasi tetap di queue dengan retry_count naik', () async {
      await offlineSvc.enqueue(OfflineOpKind.collegeCheck, {
        'item_type': 'pl',
        'checked': 'true',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemId: any(named: 'itemId'),
            itemType: any(named: 'itemType'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            jamMulai: any(named: 'jamMulai'),
            jamSelesai: any(named: 'jamSelesai'),
            tipe: any(named: 'tipe'),
          )).thenThrow(Exception('Still offline'));

      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(() async {
        container.dispose();
        await ctrl.close();
      });

      await container.read(collegeJournalProvider.notifier).load();
      await container.read(collegeJournalProvider.notifier).syncPending();

      expect(await offlineSvc.pendingCount(), 1);
      final ops = await offlineSvc.pending();
      expect(ops.first.retryCount, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 5: Auto-sync
  // ─────────────────────────────────────────────────────────────
  group('Auto-sync saat online', () {
    test('syncPending dipanggil otomatis saat connectivity kembali true', () async {
      await offlineSvc.enqueue(OfflineOpKind.collegeCheck, {
        'item_type': 'pb',
        'checked': 'true',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemId: any(named: 'itemId'),
            itemType: any(named: 'itemType'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            jamMulai: any(named: 'jamMulai'),
            jamSelesai: any(named: 'jamSelesai'),
            tipe: any(named: 'tipe'),
          )).thenAnswer((_) async => _fakeCollegeSnapshot());

      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(() async {
        container.dispose();
        await ctrl.close();
      });

      container.read(collegeJournalProvider);
      await container.read(collegeJournalProvider.notifier).load();

      ctrl.add(true);
      await Future.delayed(const Duration(milliseconds: 150));

      expect(await offlineSvc.pendingCount(), 0);
    });
  });
}
