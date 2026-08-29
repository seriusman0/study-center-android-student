import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/college_journal_model.dart';
import '../models/college_profile_model.dart';
import '../repositories/college_repository.dart';
import '../../../core/providers/journal_sync_signal.dart';

class CollegeJournalState {
  final CollegeJournalSnapshot? snapshot;
  final bool loading;
  final String? error;
  final DateTime selectedDate;
  final int pendingOfflineOps;
  final CollegeProfile? profile;
  final bool isOnline;

  CollegeJournalState({
    this.snapshot,
    this.loading = false,
    this.error,
    DateTime? selectedDate,
    this.pendingOfflineOps = 0,
    this.profile,
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

  CollegeJournalState copyWith({
    CollegeJournalSnapshot? snapshot,
    bool? loading,
    String? error,
    DateTime? selectedDate,
    int? pendingOfflineOps,
    CollegeProfile? profile,
    bool? isOnline,
  }) => CollegeJournalState(
          snapshot: snapshot ?? this.snapshot,
          loading: loading ?? this.loading,
          error: error,
          selectedDate: selectedDate ?? this.selectedDate,
          pendingOfflineOps: pendingOfflineOps ?? this.pendingOfflineOps,
          profile: profile ?? this.profile,
          isOnline: isOnline ?? this.isOnline,
        );
}

class CollegeJournalNotifier extends Notifier<CollegeJournalState> {
  ProviderSubscription? _syncSub;
  ProviderSubscription? _connSub;

  @override
  CollegeJournalState build() {
    // Auto-sync when the app signals network is restored.
    _syncSub = ref.listen<int>(
      journalSyncSignalProvider,
      (_, __) => syncPending(),
    );

    // Also sync immediately when connectivity changes to online.
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
    _loadProfile();
    ref.onDispose(() {
      _syncSub?.close();
      _connSub?.close();
    });
    return CollegeJournalState();
  }

  Future<void> _initConnectivity() async {
    final conn = await ref.read(connectivityProvider.future);
    state = state.copyWith(isOnline: conn);
  }

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadProfile() => _loadProfile();

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(collegeJournalRepositoryProvider).profile();
      if (state.snapshot != null && state.profile == null) {
        state = state.copyWith(profile: profile);
      } else {
        state = state.copyWith(profile: profile);
      }
    } catch (e) {
      debugPrint('[CollegeJournal] profile load error: $e');
    }
  }

  /// Load today or a specific date snapshot.
  Future<void> load({DateTime? date}) async {
    // Guard against concurrent loads — prevents mid-frame state mutation
    // that crashes RenderViewport (parentDataDirty assertion + null child).
    if (state.loading) return;
    final target = date ?? state.selectedDate;
    state = state.copyWith(loading: true, error: null, selectedDate: target);
    try {
      final snap = await ref.read(collegeJournalRepositoryProvider).today(
            date: state.isToday ? null : _dateString(target),
          );
      state = state.copyWith(snapshot: snap, loading: false, isOnline: true);
      _refreshPendingCount();
    } catch (e) {
      debugPrint('[CollegeJournal] load() error: $e');
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
    final today = CollegeJournalState._today();
    load(date: today);
  }

  // ── Sync helpers ─────────────────────────────────────────────────────────
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

    debugPrint('[CollegeJournal] Syncing ${ops.length} pending operation(s)...');
    for (final op in ops) {
      try {
        await _replayCollegeOp(op);
        await svc.remove(op.id!);
        debugPrint('[CollegeJournal] Synced op id=${op.id} (${op.kind}) - removed');
      } catch (e) {
        final exceeded = await svc.markRetry(op.id!, op.retryCount ?? 0);
        if (exceeded) {
          debugPrint('[CollegeJournal] Op id=${op.id} exceeded max retries - removing');
          await svc.remove(op.id!);
        } else {
          debugPrint('[CollegeJournal] Op id=${op.id} retry failed: $e');
        }
      }
    }
    await _refreshPendingCount();
    if (state.snapshot != null) {
      await load();
    }
  }

  Future<void> _replayCollegeOp(OfflineOperation op) async {
    final p = op.payload;
    final repo = ref.read(collegeJournalRepositoryProvider);

    switch (op.kind) {
      case OfflineOpKind.collegeCheck:
        await repo.check(
          itemType: p['item_type'] as String,
          itemId: p['item_id'] != null ? int.tryParse(p['item_id'] as String) : null,
          checked: p['checked'] == 'true',
          date: p['date'] as String?,
          jamMulai: p['jam_mulai'] as String?,
          jamSelesai: p['jam_selesai'] as String?,
          tipe: p['tipe'] as String?,
        );
        break;
      case OfflineOpKind.collegeStudyLog:
        await repo.check(
          itemType: 'study',
          itemId: int.tryParse(p['item_id'] as String),
          date: p['date'] as String?,
          jamMulai: p['jam_mulai'] as String?,
          jamSelesai: p['jam_selesai'] as String?,
          tipe: p['tipe'] as String?,
        );
        break;
      case OfflineOpKind.collegeFoto:
        // Photo upload is binary — stored differently; skip if bytes not available
        debugPrint('[CollegeJournal] Photo upload op cannot be replayed without bytes');
        break;
      default:
        debugPrint('[CollegeJournal] Unknown op kind: ${op.kind}');
        break;
    }
  }

  Future<void> _enqueue(OfflineOpKind kind, Map<String, dynamic> payload) async {
    await ref.read(offlineServiceProvider).enqueue(kind, payload);
    await _refreshPendingCount();
  }

  // ── Mutations ────────────────────────────────────────────────────────────

  /// Toggle PL/PB bible reading
  Future<void> checkBible(String type, bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    // Optimistic update
    final updated = snap.copyWith(
      biblePlChecked: type == 'pl' ? checked : snap.bible.plChecked,
      biblePbChecked: type == 'pb' ? checked : snap.bible.pbChecked,
    );
    state = state.copyWith(snapshot: updated);

    if (!state.isOnline) {
      await _enqueue(OfflineOpKind.collegeCheck, {
        'item_type': type,
        'checked': checked.toString(),
        'date': snap.date,
      });
      return;
    }

    try {
      final result = await ref.read(collegeJournalRepositoryProvider).check(
            itemType: type,
            checked: checked,
            date: snap.date,
          );
      state = state.copyWith(snapshot: result);
    } catch (e) {
      debugPrint('[CollegeJournal] checkBible error: $e');
      await _enqueue(OfflineOpKind.collegeCheck, {
        'item_type': type,
        'checked': checked.toString(),
        'date': snap.date,
      });
    }
  }

  /// Toggle a life item (check or boolean response_type)
  Future<void> checkLife(int itemId, bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    final updatedItems = snap.lifeItems
        .map((i) => i.id == itemId ? i.copyWith(checked: checked) : i)
        .toList();
    final updated = snap.copyWith(lifeItems: updatedItems);
    state = state.copyWith(snapshot: updated);

    if (!state.isOnline) {
      await _enqueue(OfflineOpKind.collegeCheck, {
        'item_type': 'life',
        'item_id': itemId.toString(),
        'checked': checked.toString(),
        'date': snap.date,
      });
      return;
    }

    try {
      final result = await ref.read(collegeJournalRepositoryProvider).check(
            itemType: 'life',
            itemId: itemId,
            checked: checked,
            date: snap.date,
          );
      state = state.copyWith(snapshot: result);
    } catch (e) {
      await _enqueue(OfflineOpKind.collegeCheck, {
        'item_type': 'life',
        'item_id': itemId.toString(),
        'checked': checked.toString(),
        'date': snap.date,
      });
    }
  }

  /// Toggle a boolean life item (Sudah/Belum — sends checked as boolean)
  Future<void> toggleBoolean(int itemId, bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    final updatedItems = snap.lifeItems
        .map((i) => i.id == itemId ? i.copyWith(checked: checked) : i)
        .toList();
    final updated = snap.copyWith(lifeItems: updatedItems);
    state = state.copyWith(snapshot: updated);

    if (!state.isOnline) {
      await _enqueue(OfflineOpKind.collegeCheck, {
        'item_type': 'life',
        'item_id': itemId.toString(),
        'checked': checked.toString(),
        'date': snap.date,
      });
      return;
    }

    try {
      final result = await ref.read(collegeJournalRepositoryProvider).check(
            itemType: 'life',
            itemId: itemId,
            checked: checked,
            date: snap.date,
          );
      state = state.copyWith(snapshot: result);
    } catch (e) {
      await _enqueue(OfflineOpKind.collegeCheck, {
        'item_type': 'life',
        'item_id': itemId.toString(),
        'checked': checked.toString(),
        'date': snap.date,
      });
    }
  }

  /// Save study log (time_range item) with jam_mulai/jam_selesai
  Future<void> saveStudyLog(int itemId, String jamMulai, String jamSelesai, String? tipe) async {
    final snap = state.snapshot;
    if (snap == null) return;

    // Optimistic update of study_logs map
    final updatedLogs = Map<int, StudyLog>.from(snap.studyLogs);
    updatedLogs[itemId] = StudyLog(
      itemId:     itemId,
      jamMulai:   jamMulai,
      jamSelesai: jamSelesai,
      tipe:       tipe ?? 'mandiri',
    );

    // If both empty, remove the log (clear)
    final isClear = jamMulai.isEmpty && jamSelesai.isEmpty;
    if (isClear) {
      updatedLogs.remove(itemId);
    }

    final updated = snap.copyWith(
      lifeItems: snap.lifeItems
          .map((i) => i.id == itemId ? i.copyWith(checked: !isClear) : i)
          .toList(),
      studyLogs: updatedLogs,
    );
    state = state.copyWith(snapshot: updated);

    if (!state.isOnline) {
      await _enqueue(OfflineOpKind.collegeStudyLog, {
        'item_type': 'study',
        'item_id': itemId.toString(),
        'checked': (!isClear).toString(),
        'date': snap.date,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'tipe': tipe ?? 'mandiri',
      });
      return;
    }

    try {
      final result = await ref.read(collegeJournalRepositoryProvider).check(
            itemType: 'study',
            itemId: itemId,
            date: snap.date,
            jamMulai: jamMulai,
            jamSelesai: jamSelesai,
            tipe: tipe ?? 'mandiri',
          );
      state = state.copyWith(snapshot: result);
    } catch (e) {
      await _enqueue(OfflineOpKind.collegeStudyLog, {
        'item_type': 'study',
        'item_id': itemId.toString(),
        'checked': (!isClear).toString(),
        'date': snap.date,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'tipe': tipe ?? 'mandiri',
      });
    }
  }

  /// Upload foto belajar (camera/gallery)
  Future<void> uploadPhoto(XFile file) async {
    final snap = state.snapshot;
    if (snap == null) return;

    try {
      final bytes = await file.readAsBytes();
      final result = await ref.read(collegeJournalRepositoryProvider)
          .uploadPhoto(bytes, file.name, snap.date);
      state = state.copyWith(snapshot: result, isOnline: true);
    } catch (e) {
      debugPrint('[CollegeJournal] uploadPhoto error: $e');
      // Queue for later — but we can't store binary easily in SQLite;
      // for offline, show error and let user retry when online
      rethrow;
    }
  }

  Future<void> deletePhoto() async {
    final snap = state.snapshot;
    if (snap == null) return;
    try {
      final result = await ref.read(collegeJournalRepositoryProvider)
          .deletePhoto(snap.date);
      state = state.copyWith(snapshot: result);
    } catch (e) {
      debugPrint('[CollegeJournal] deletePhoto error: $e');
      rethrow;
    }
  }
}

final collegeJournalProvider =
    NotifierProvider<CollegeJournalNotifier, CollegeJournalState>(CollegeJournalNotifier.new);
