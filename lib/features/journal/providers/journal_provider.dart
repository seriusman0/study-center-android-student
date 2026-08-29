import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/journal_model.dart';
import '../repositories/journal_repository.dart';
import '../../../core/providers/journal_sync_signal.dart';

class JournalState {
  final JournalSnapshot? snapshot;
  final bool loading;
  final String? error;
  final DateTime selectedDate;
  final int pendingOfflineOps;

  JournalState({
    this.snapshot,
    this.loading = false,
    this.error,
    DateTime? selectedDate,
    this.pendingOfflineOps = 0,
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

  JournalState copyWith({
    JournalSnapshot? snapshot,
    bool? loading,
    String? error,
    DateTime? selectedDate,
    int? pendingOfflineOps,
  }) =>
      JournalState(
        snapshot: snapshot ?? this.snapshot,
        loading: loading ?? this.loading,
        error: error,
        selectedDate: selectedDate ?? this.selectedDate,
        pendingOfflineOps: pendingOfflineOps ?? this.pendingOfflineOps,
      );
}

class JournalNotifier extends Notifier<JournalState> {
  ProviderSubscription? _syncSub;
  ProviderSubscription? _connSub;

  @override
  JournalState build() {
    // Auto-sync when the app signals network is restored.
    _syncSub = ref.listen<int>(
      journalSyncSignalProvider.select((s) => s),
      (_, __) => syncPending(),
    );

    // Also sync immediately when connectivity changes to online.
    _connSub = ref.listen<bool>(
      connectivityProvider.select((s) => s.valueOrNull ?? false),
      (prev, online) {
        if (online) syncPending();
      },
    );

    ref.onDispose(() {
      _syncSub?.close();
      _connSub?.close();
    });
    return JournalState();
  }

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load({DateTime? date}) async {
    // Guard against concurrent loads — prevents mid-frame state mutation
    // that crashes RenderViewport (parentDataDirty assertion + null child).
    if (state.loading) return;
    final target = date ?? state.selectedDate;
    state = state.copyWith(loading: true, error: null, selectedDate: target);
    try {
      final snap = await ref.read(journalRepositoryProvider).today(
            date: state.isToday ? null : _dateString(target),
          );
      state = state.copyWith(snapshot: snap, loading: false);
      // Refresh pending count now that we're online.
      _refreshPendingCount();
    } catch (e) {
      debugPrint('[Journal] load() error: $e');
      state = JournalState(error: e.toString(), selectedDate: target);
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
    final today = JournalState._today();
    load(date: today);
  }

  Future<void> _checkRemote(OfflineOpKind kind, Map<String, dynamic> p) async {
    final repo = ref.read(journalRepositoryProvider);
    final pType = p['item_type'] as String? ?? '';
    if (kind == OfflineOpKind.checkBible) {
      await repo.check(
        itemType: pType,
        checked: p['checked'] == 'true',
        date: p['date'] as String,
      );
    } else if (kind == OfflineOpKind.saveVerse) {
      await repo.check(
        itemType: 'verse',
        checked: (p['verse_ref'] as String).isNotEmpty,
        verseRef: p['verse_ref'] as String,
        date: p['date'] as String,
      );
    } else if (kind == OfflineOpKind.checkLife) {
      await repo.check(
        itemType: 'life',
        itemId: int.parse(p['item_id'] as String),
        checked: p['checked'] == 'true',
        date: p['date'] as String,
      );
    } else if (kind == OfflineOpKind.checkVerseCheck) {
      await repo.check(
        itemType: 'verse_check',
        checked: p['checked'] == 'true',
        date: p['date'] as String,
      );
    }
  }

  Future<void> _enqueue(OfflineOpKind kind, Map<String, dynamic> payload) async {
    await ref.read(offlineServiceProvider).enqueue(kind, payload);
    await _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    final count = await ref.read(offlineServiceProvider).pendingCount();
    if (state.pendingOfflineOps != count) {
      state = state.copyWith(pendingOfflineOps: count);
    }
  }

  // ── Sync ─────────────────────────────────────────────────────────────────

  /// Replay all queued offline operations. Called automatically when connectivity
  /// is restored, or manually from a "Sync Now" button.
  Future<void> syncPending() async {
    final svc = ref.read(offlineServiceProvider);
    final ops = await svc.pending();
    if (ops.isEmpty) return;

    debugPrint('[Journal] Syncing ${ops.length} pending operation(s)…');
    for (final op in ops) {
      try {
        await _checkRemote(op.kind, op.payload);
        await svc.remove(op.id!);
        debugPrint('[Journal] Synced op id=${op.id} (${op.kind}) — removed from queue');
      } catch (e) {
        final exceeded = await svc.markRetry(op.id!, op.retryCount ?? 0);
        if (exceeded) {
          debugPrint('[Journal] Op id=${op.id} exceeded max retries — removing');
          await svc.remove(op.id!);
        } else {
          debugPrint('[Journal] Op id=${op.id} retry failed: $e');
        }
      }
    }
    await _refreshPendingCount();
    // Reload the current day's snapshot so UI reflects synced state.
    if (state.snapshot != null) {
      await load();
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> checkBible(String type, bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    // Optimistic update.
    final updated = snap.copyWith(
      bible: type == 'pl'
          ? snap.bible.copyWith(plChecked: checked)
          : snap.bible.copyWith(pbChecked: checked),
    );
    state = state.copyWith(snapshot: updated);

    try {
      final result = await ref.read(journalRepositoryProvider).check(
            itemType: type,
            checked: checked,
            date: snap.date,
          );
      state = state.copyWith(snapshot: result);
    } catch (_) {
      // Network error — queue for later sync instead of reverting.
      await _enqueue(OfflineOpKind.checkBible, {
        'item_type': type,
        'checked': checked.toString(),
        'date': snap.date,
      });
    }
  }

  /// Simpan teks ayat (verse_ref) — per-minggu, shared.
  /// TIDAK mengubah verseChecked (centang per-hari terpisah).
  Future<void> saveVerseRef(String? verseRef) async {
    final snap = state.snapshot;
    if (snap == null) return;

    final updated = snap.copyWith(
      verseRef: verseRef,
      clearVerseRef: verseRef == null,
    );
    state = state.copyWith(snapshot: updated);

    try {
      final result = await ref.read(journalRepositoryProvider).check(
            itemType: 'verse',
            checked: verseRef != null && verseRef.isNotEmpty,
            verseRef: verseRef,
            date: snap.date,
          );
      state = state.copyWith(snapshot: result);
    } catch (_) {
      await _enqueue(OfflineOpKind.saveVerse, {
        'verse_ref': verseRef ?? '',
        'date': snap.date,
      });
    }
  }

  /// Centang/hapus centang hafalan per-hari (verse_check).
  /// verse_ref (teks ayat) harus sudah ada; jika tidak, operasi dibatalkan.
  Future<void> checkVerseChecked(bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    // Optimistic update.
    final updated = snap.copyWith(verseChecked: checked);
    state = state.copyWith(snapshot: updated);

    try {
      final result = await ref.read(journalRepositoryProvider).check(
            itemType: 'verse_check',
            checked: checked,
            date: snap.date,
          );
      state = state.copyWith(snapshot: result);
    } catch (_) {
      // Queue for offline sync.
      await _enqueue(OfflineOpKind.checkVerseCheck, {
        'item_type': 'verse_check',
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
    final updated = snap.copyWith(lifeItems: updatedItems);
    state = state.copyWith(snapshot: updated);

    try {
      final result = await ref.read(journalRepositoryProvider).check(
            itemType: 'life',
            itemId: itemId,
            checked: checked,
            date: snap.date,
          );
      state = state.copyWith(snapshot: result);
    } catch (_) {
      await _enqueue(OfflineOpKind.checkLife, {
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
      final result = await ref.read(journalRepositoryProvider)
          .uploadPhoto(bytes, file.name, snap.date);
      state = state.copyWith(snapshot: result);
    } catch (e) {
      debugPrint('[Journal] uploadPhoto error: $e');
      rethrow;
    }
  }

  Future<void> deletePhoto() async {
    final snap = state.snapshot;
    if (snap == null) return;

    try {
      final result = await ref.read(journalRepositoryProvider)
          .deletePhoto(snap.date);
      state = state.copyWith(snapshot: result);
    } catch (e) {
      debugPrint('[Journal] deletePhoto error: $e');
      rethrow;
    }
  }
}

final journalProvider =
    NotifierProvider<JournalNotifier, JournalState>(JournalNotifier.new);
