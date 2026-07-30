import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_model.dart';
import '../repositories/journal_repository.dart';

class JournalState {
  final JournalSnapshot? snapshot;
  final bool loading;
  final String? error;

  const JournalState({this.snapshot, this.loading = false, this.error});

  JournalState copyWith({JournalSnapshot? snapshot, bool? loading, String? error}) =>
      JournalState(snapshot: snapshot ?? this.snapshot, loading: loading ?? this.loading, error: error);
}

class JournalNotifier extends Notifier<JournalState> {
  @override
  JournalState build() => const JournalState();

  Future<void> load() async {
    debugPrint('[Journal] load() start, snapshot=${state.snapshot != null}');
    state = state.copyWith(loading: true, error: null);
    try {
      final snap = await ref.read(journalRepositoryProvider).today();
      debugPrint('[Journal] load() success, items=${snap.lifeItems.length}');
      state = state.copyWith(snapshot: snap, loading: false);
    } catch (e) {
      debugPrint('[Journal] load() error: $e');
      state = JournalState(error: e.toString());
    }
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
      throw e;
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
      throw e;
    }
  }
}

final journalProvider = NotifierProvider<JournalNotifier, JournalState>(JournalNotifier.new);
