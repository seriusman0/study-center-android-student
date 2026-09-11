// ignore_for_file: avoid_print

/// Unit test untuk ScholarshipTeenagerJournalNotifier — offline queue dan sync.
///
/// Jalankan:
///   flutter test test/features/scholarship/scholarship_journal_provider_test.dart
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sc_student/core/services/connectivity_service.dart';
import 'package:sc_student/core/services/offline_service.dart';
import 'package:sc_student/features/college/models/college_journal_model.dart';
import 'package:sc_student/features/scholarship_teenager/providers/scholarship_teenager_journal_provider.dart';
import 'package:sc_student/features/scholarship_teenager/repositories/scholarship_teenager_journal_repository.dart';
import '../../helpers/offline_test_helper.dart';

// ── Mocks ──────────────────────────────────────────────────────
class MockScholarshipRepo extends Mock
    implements ScholarshipTeenagerJournalRepository {}

// ── Fake helpers ───────────────────────────────────────────────
CollegeJournalSnapshot _fakeSnapshot() {
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
      {'id': 20, 'kategori': 'kerohanian', 'label': 'Doa', 'response_type': 'check', 'checked': false},
      {'id': 21, 'kategori': 'rohani', 'label': 'Ibadah', 'response_type': 'boolean', 'checked': false},
    ],
    'study_logs': [],
    'config': {},
  });
}

// ── Container builder ───────────────────────────────────────────
ProviderContainer _makeContainer({
  required ScholarshipTeenagerJournalRepository repo,
  required OfflineService offline,
  required Stream<bool> connectivityStream,
}) {
  return ProviderContainer(
    overrides: [
      scholarshipTeenagerJournalRepositoryProvider.overrideWithValue(repo),
      offlineServiceProvider.overrideWithValue(offline),
      connectivityProvider.overrideWith((ref) => connectivityStream),
    ],
  );
}

void main() {
  setUpAll(initTestDatabase);

  late MockScholarshipRepo mockRepo;
  late OfflineService offlineSvc;

  setUp(() async {
    mockRepo = MockScholarshipRepo();
    offlineSvc = await makeTestOfflineService();

    when(() => mockRepo.today(date: any(named: 'date')))
        .thenAnswer((_) async => _fakeSnapshot());
    when(() => mockRepo.check(
          itemType: any(named: 'itemType'),
          itemId: any(named: 'itemId'),
          checked: any(named: 'checked'),
          date: any(named: 'date'),
          verseRef: any(named: 'verseRef'),
        )).thenAnswer((_) async => _fakeSnapshot());
  });

  tearDown(() async {
    await offlineSvc.close();
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 1: Load
  // ─────────────────────────────────────────────────────────────
  group('ScholarshipTeenagerJournalNotifier.load()', () {
    test('load berhasil mengisi snapshot', () async {
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

      await container.read(scholarshipTeenagerJournalProvider.notifier).load();

      final s = container.read(scholarshipTeenagerJournalProvider);
      expect(s.snapshot, isNotNull);
      expect(s.loading, false);
      expect(s.error, isNull);
    });

    test('load error mengisi state.error', () async {
      when(() => mockRepo.today(date: any(named: 'date')))
          .thenThrow(Exception('Network error'));

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

      await container.read(scholarshipTeenagerJournalProvider.notifier).load();
      expect(container.read(scholarshipTeenagerJournalProvider).error, isNotNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 2: Offline queue
  // ─────────────────────────────────────────────────────────────
  group('Offline queue — checkBible', () {
    test('checkBible("pl") enqueue saat network error', () async {
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            verseRef: any(named: 'verseRef'),
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

      await container.read(scholarshipTeenagerJournalProvider.notifier).load();
      await container.read(scholarshipTeenagerJournalProvider.notifier).checkBible('pl', true);

      expect(await offlineSvc.pendingCount(), 1);
      final ops = await offlineSvc.pending();
      expect(ops.first.kind, OfflineOpKind.scholarshipCheck);
      expect(ops.first.payload['item_type'], 'pl');
      expect(ops.first.payload['checked'], 'true');
    });

    test('checkBible("pb") enqueue saat network error', () async {
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            verseRef: any(named: 'verseRef'),
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

      await container.read(scholarshipTeenagerJournalProvider.notifier).load();
      await container.read(scholarshipTeenagerJournalProvider.notifier).checkBible('pb', false);

      final ops = await offlineSvc.pending();
      expect(ops.first.payload['item_type'], 'pb');
    });
  });

  group('Offline queue — checkLife', () {
    test('checkLife enqueue saat offline', () async {
      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            verseRef: any(named: 'verseRef'),
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

      await container.read(scholarshipTeenagerJournalProvider.notifier).load();
      await container.read(scholarshipTeenagerJournalProvider.notifier).checkLife(20, true);

      final ops = await offlineSvc.pending();
      expect(ops.first.kind, OfflineOpKind.scholarshipCheck);
      expect(ops.first.payload['item_id'], '20');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 3: syncPending
  // ─────────────────────────────────────────────────────────────
  group('syncPending()', () {
    test('memproses scholarshipCheck dan mengosongkan queue', () async {
      await offlineSvc.enqueue(OfflineOpKind.scholarshipCheck, {
        'item_type': 'pl',
        'checked': 'true',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            verseRef: any(named: 'verseRef'),
          )).thenAnswer((_) async => _fakeSnapshot());

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

      await container.read(scholarshipTeenagerJournalProvider.notifier).load();
      await container.read(scholarshipTeenagerJournalProvider.notifier).syncPending();

      expect(await offlineSvc.pendingCount(), 0);
    });

    test('retry gagal → operasi tetap dengan retry_count naik', () async {
      await offlineSvc.enqueue(OfflineOpKind.scholarshipCheck, {
        'item_type': 'pl',
        'checked': 'true',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            verseRef: any(named: 'verseRef'),
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

      await container.read(scholarshipTeenagerJournalProvider.notifier).load();
      await container.read(scholarshipTeenagerJournalProvider.notifier).syncPending();

      expect(await offlineSvc.pendingCount(), 1);
      final ops = await offlineSvc.pending();
      expect(ops.first.retryCount, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GROUP 4: Auto-sync
  // ─────────────────────────────────────────────────────────────
  group('Auto-sync saat online', () {
    test('syncPending dipanggil otomatis saat connectivity kembali true', () async {
      await offlineSvc.enqueue(OfflineOpKind.scholarshipCheck, {
        'item_type': 'pb',
        'checked': 'true',
        'date': '2024-09-01',
      });

      when(() => mockRepo.check(
            itemType: any(named: 'itemType'),
            itemId: any(named: 'itemId'),
            checked: any(named: 'checked'),
            date: any(named: 'date'),
            verseRef: any(named: 'verseRef'),
          )).thenAnswer((_) async => _fakeSnapshot());

      final ctrl = StreamController<bool>.broadcast();
      final container = _makeContainer(
        repo: mockRepo,
        offline: offlineSvc,
        connectivityStream: ctrl.stream,
      );
      addTearDown(container.dispose);
      addTearDown(ctrl.close);

      container.read(scholarshipTeenagerJournalProvider);
      await container.read(scholarshipTeenagerJournalProvider.notifier).load();

      ctrl.add(true);
      await Future.delayed(const Duration(milliseconds: 150));

      expect(await offlineSvc.pendingCount(), 0);
    });
  });
}
