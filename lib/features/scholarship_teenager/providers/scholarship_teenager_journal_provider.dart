import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/providers/journal_sync_signal.dart';
import '../../college/models/college_journal_model.dart';
import '../repositories/scholarship_teenager_journal_repository.dart';

/// State for the scholarship_teenager journal.
/// Mirrors [CollegeJournalState] but without study_log support.
class ScholarshipJournalState {
  final CollegeJournalSnapshot? snapshot;
  final bool loading;
  final String? error;
  final DateTime selectedDate;
  final int pendingOfflineOps;
  final bool isOnline;

  ScholarshipJournalState({
    this.snapshot,
    this.loading = false,
    this.error,
    DateTime? selectedDate,
    this.pendingOfflineOps = 0,
    this.isOnline = true,
  }) : selectedDate = selectedDate ?? _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isToday {
    final t = _today();
    return selectedDate.year == t.year &&
        selectedDate.month == t.month &&
        selectedDate.day == t.day;
  }

  ScholarshipJournalState copyWith({
    CollegeJournalSnapshot? snapshot,
    bool? loading,
    String? error,
    DateTime? selectedDate,
    int? pendingOfflineOps,
    bool? isOnline,
  }) =>
      ScholarshipJournalState(
        snapshot: snapshot ?? this.snapshot,
        loading: loading ?? this.loading,
        error: error,
        selectedDate: selectedDate ?? this.selectedDate,
        pendingOfflineOps: pendingOfflineOps ?? this.pendingOfflineOps,
        isOnline: isOnline ?? this.isOnline,
      );
}

class ScholarshipTeenagerJournalNotifier
    extends Notifier<ScholarshipJournalState> {
  ProviderSubscription? _syncSub;
  ProviderSubscription? _connSub;

  @override
  ScholarshipJournalState build() {
    _syncSub = ref.listen<int>(
      journalSyncSignalProvider,
      (_, __) => syncPending(),
    );

    _connSub = ref.listen<bool>(
      connectivityProvider.select((s) => s.valueOrNull ?? false),
      (prev, online) {
        if (online) {
          syncPending();
        } else {
          state = state.copyWith(isOnline: false);
        }
      },
    );

    _initConnectivity();
    ref.onDispose(() {
      _syncSub?.close();
      _connSub?.close();
    });
    return ScholarshipJournalState();
  }

  Future<void> _initConnectivity() async {
    final conn = await ref.read(connectivityProvider.future);
    state = state.copyWith(isOnline: conn);
  }

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load({DateTime? date}) async {
    if (state.loading) return;
    final target = date ?? state.selectedDate;
    state = state.copyWith(loading: true, error: null, selectedDate: target);
    try {
      final snap = await ref
          .read(scholarshipTeenagerJournalRepositoryProvider)
          .today(date: state.isToday ? null : _dateString(target));
      state = state.copyWith(snapshot: snap, loading: false, isOnline: true);
      _refreshPendingCount();
    } catch (e) {
      debugPrint('[ScholarshipJournal] load() error: $e');
      state = state.copyWith(
        error: e.toString(),
        loading: false,
        isOnline: false,
        selectedDate: target,
      );
    }
  }

  void goToPrevDay() {
    final prev = state.selectedDate.subtract(const Duration(days: 1));
    load(date: prev);
  }

  void goToNextDay() {
    if (state.isToday) return;
    final next = state.selectedDate.add(const Duration(days: 1));
    load(date: next);
  }

  void goToToday() {
    load(date: ScholarshipJournalState._today());
  }

  // ── Sync helpers ────────────────────────────────────────────────────────────

  Future<void> _refreshPendingCount() async {
    final count = await ref.read(offlineServiceProvider).pendingCount();
    if (state.pendingOfflineOps != count) {
      state = state.copyWith(pendingOfflineOps: count);
    }
  }

  Future<void> syncPending() async {
    final svc = ref.read(offlineServiceProvider);
    final ops = await svc.pending();
    if (ops.isEmpty) return;

    debugPrint(
        '[ScholarshipJournal] Syncing ${ops.length} pending operation(s)...');
    for (final op in ops) {
      try {
        await _replayOp(op);
        await svc.remove(op.id!);
      } catch (e) {
        final exceeded = await svc.markRetry(op.id!, op.retryCount ?? 0);
        if (exceeded) {
          await svc.remove(op.id!);
        }
      }
    }
    await _refreshPendingCount();
    if (state.snapshot != null) await load();
  }

  Future<void> _replayOp(OfflineOperation op) async {
    final p = op.payload;
    final repo = ref.read(scholarshipTeenagerJournalRepositoryProvider);

    switch (op.kind) {
      case OfflineOpKind.scholarshipCheck:
        await repo.check(
          itemType: p['item_type'] as String,
          itemId:
              p['item_id'] != null ? int.tryParse(p['item_id'] as String) : null,
          checked: p['checked'] == 'true',
          date: p['date'] as String?,
        );
        break;
      default:
        debugPrint('[ScholarshipJournal] Unknown op kind: ${op.kind}');
        break;
    }
  }

  Future<void> _enqueue(
      OfflineOpKind kind, Map<String, dynamic> payload) async {
    await ref.read(offlineServiceProvider).enqueue(kind, payload);
    await _refreshPendingCount();
  }

  // ── Mutations ────────────────────────────────────────────────────────────────

  Future<void> checkBible(String type, bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    final updated = snap.copyWith(
      biblePlChecked: type == 'pl' ? checked : snap.bible.plChecked,
      biblePbChecked: type == 'pb' ? checked : snap.bible.pbChecked,
    );
    state = state.copyWith(snapshot: updated);

    if (!state.isOnline) {
      await _enqueue(OfflineOpKind.scholarshipCheck, {
        'item_type': type,
        'checked': checked.toString(),
        'date': snap.date,
      });
      return;
    }

    try {
      final result = await ref
          .read(scholarshipTeenagerJournalRepositoryProvider)
          .check(itemType: type, checked: checked, date: snap.date);
      state = state.copyWith(snapshot: result);
    } catch (e) {
      debugPrint('[ScholarshipJournal] checkBible error: $e');
      await _enqueue(OfflineOpKind.scholarshipCheck, {
        'item_type': type,
        'checked': checked.toString(),
        'date': snap.date,
      });
    }
  }

  Future<void> checkLife(int itemId, bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    final updatedItems = snap.lifeItems
        .map((i) => i.id == itemId ? i.copyWith(checked: checked) : i)
        .toList();
    state = state.copyWith(snapshot: snap.copyWith(lifeItems: updatedItems));

    if (!state.isOnline) {
      await _enqueue(OfflineOpKind.scholarshipCheck, {
        'item_type': 'life',
        'item_id': itemId.toString(),
        'checked': checked.toString(),
        'date': snap.date,
      });
      return;
    }

    try {
      final result = await ref
          .read(scholarshipTeenagerJournalRepositoryProvider)
          .check(
              itemType: 'life',
              itemId: itemId,
              checked: checked,
              date: snap.date);
      state = state.copyWith(snapshot: result);
    } catch (e) {
      await _enqueue(OfflineOpKind.scholarshipCheck, {
        'item_type': 'life',
        'item_id': itemId.toString(),
        'checked': checked.toString(),
        'date': snap.date,
      });
    }
  }

  Future<void> uploadPhoto(XFile file) async {
    final snap = state.snapshot;
    if (snap == null) return;

    try {
      final bytes = await file.readAsBytes();
      final result = await ref
          .read(scholarshipTeenagerJournalRepositoryProvider)
          .uploadPhoto(bytes, file.name, snap.date);
      state = state.copyWith(snapshot: result, isOnline: true);
    } catch (e) {
      debugPrint('[ScholarshipJournal] uploadPhoto error: $e');
      rethrow;
    }
  }

  Future<void> deletePhoto() async {
    final snap = state.snapshot;
    if (snap == null) return;
    try {
      final result = await ref
          .read(scholarshipTeenagerJournalRepositoryProvider)
          .deletePhoto(snap.date);
      state = state.copyWith(snapshot: result);
    } catch (e) {
      debugPrint('[ScholarshipJournal] deletePhoto error: $e');
      rethrow;
    }
  }
}

final scholarshipTeenagerJournalProvider = NotifierProvider<
    ScholarshipTeenagerJournalNotifier,
    ScholarshipJournalState>(ScholarshipTeenagerJournalNotifier.new);
