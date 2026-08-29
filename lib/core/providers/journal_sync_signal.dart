import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sentinel provider: invalidating this signals the JournalNotifier to
/// trigger an immediate sync pass.  Incrementing this int provider from
/// anywhere in the app will fire the listener in JournalNotifier.
final journalSyncSignalProvider = StateProvider<int>((ref) => 0);
