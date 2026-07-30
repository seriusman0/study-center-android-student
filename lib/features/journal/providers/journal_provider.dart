import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_model.dart';
import '../repositories/journal_repository.dart';

class JournalState {
  final JournalSnapshot? snapshot;
  final bool loading;
  final String? error;
  final DateTime selectedDate;

  JournalState({
    this.snapshot,
    this.loading = false,
    this.error,
    DateTime? selectedDate,
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
  }) =>
      JournalState(
        snapshot: snapshot ?? this.snapshot,
        loading: loading ?? this.loading,
        error: error,
        selectedDate: selectedDate ?? this.selectedDate,
      );
}

class JournalNotifier extends Notifier<JournalState> {
  @override
  JournalState build() => JournalState();

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load({DateTime? date}) async {
    final target = date ?? state.selectedDate;
    state = state.copyWith(loading: true, error: null, selectedDate: target);
    try {
      final snap = await ref.read(journalRepositoryProvider).today(
            date: state.isToday ? null : _dateString(target),
          );
      state = state.copyWith(snapshot: snap, loading: false);
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

  Future<void> checkBible(String type, bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    final updated = JournalSnapshot(
      date: snap.date,
      bible: type == 'pl'
          ? snap.bible.copyWith(plChecked: checked)
          : snap.bible.copyWith(pbChecked: checked),
      verseRef: snap.verseRef,
      lifeItems: snap.lifeItems,
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
      state = state.copyWith(snapshot: snap);
    }
  }

  Future<void> saveVerseRef(String? verseRef) async {
    final snap = state.snapshot;
    if (snap == null) return;

    final updated = JournalSnapshot(
      date: snap.date,
      bible: snap.bible,
      verseRef: verseRef,
      lifeItems: snap.lifeItems,
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
      state = state.copyWith(snapshot: snap);
    }
  }

  Future<void> checkLife(int itemId, bool checked) async {
    final snap = state.snapshot;
    if (snap == null) return;

    final updatedItems = snap.lifeItems.map((i) => i.id == itemId ? i.copyWith(checked: checked) : i).toList();
    final updated = JournalSnapshot(date: snap.date, bible: snap.bible, verseRef: snap.verseRef, lifeItems: updatedItems);
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
      state = state.copyWith(snapshot: snap);
    }
  }

  Future<void> uploadPhoto(XFile file) async {
    final snap = state.snapshot;
    if (snap == null) return;

    try {
      final bytes = await file.readAsBytes();
      final result = await ref.read(journalRepositoryProvider).uploadPhoto(bytes, file.name, snap.date);
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
      final result = await ref.read(journalRepositoryProvider).deletePhoto(snap.date);
      state = state.copyWith(snapshot: result);
    } catch (e) {
      debugPrint('[Journal] deletePhoto error: $e');
      rethrow;
    }
  }
}

final journalProvider = NotifierProvider<JournalNotifier, JournalState>(JournalNotifier.new);
