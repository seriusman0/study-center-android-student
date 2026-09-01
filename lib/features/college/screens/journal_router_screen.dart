import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sc_student/features/auth/providers/auth_provider.dart';
import 'package:sc_student/features/auth/models/user_model.dart';
import 'package:sc_student/features/journal/screens/journal_screen.dart';
import 'package:sc_student/features/scholarship_teenager/screens/scholarship_journal_screen.dart';
import 'college_journal_screen.dart';

/// Role-aware entry point for the "Jurnal" bottom-nav tab.
///
/// Journal-eligible roles: student, college, scholarship_teenager
/// (see [UserModel.hasJournalAccess]). Each role's journal is backed by a
/// *different* API namespace (/jurnal, /college-jurnal,
/// /scholarship-teenager-jurnal) with its own data — a user with more than
/// one of these roles at once (e.g. student + scholarship_teenager, which
/// happens for scholarship recipients who are also enrolled students) has
/// two genuinely separate journals to fill in, not one. Showing only the
/// highest-priority role's journal would silently hide the other one, so
/// when a user holds 2+ journal roles we surface a tab switcher instead of
/// picking one for them.
class JournalRouterScreen extends ConsumerWidget {
  const JournalRouterScreen({super.key});

  /// Ordered (label, screen) entries for every journal-eligible role the
  /// user actually holds. Order mirrors the old single-pick priority
  /// (college > scholarship_teenager > student) so the first tab matches
  /// what single-role users already saw.
  List<(String label, Widget screen)> _journalsFor(UserModel? user) {
    if (user == null) return [('Jurnal', const JournalScreen())];
    final entries = <(String, Widget)>[];
    if (user.isCollege) {
      entries.add(('College', const CollegeJournalScreen()));
    }
    if (user.isScholarshipTeenager) {
      entries.add(('Beasiswa', const ScholarshipJournalScreen()));
    }
    if (user.isStudent) {
      entries.add(('Student', const JournalScreen()));
    }
    if (entries.isEmpty) {
      // No journal role at all — fall back to the student screen, which
      // will itself show an appropriate empty/unauthorized state.
      entries.add(('Jurnal', const JournalScreen()));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final journals = _journalsFor(user);

    // Single journal role (the common case) — no ambiguity, show it directly.
    if (journals.length == 1) {
      return journals.first.$2;
    }

    // Multiple journal roles on one account — make it explicit which
    // journal is which so entries are never entered against the wrong role.
    //
    // Each entry's screen (JournalScreen / ScholarshipJournalScreen /
    // CollegeJournalScreen) already brings its own Scaffold+AppBar (with its
    // own actions, e.g. history). Wrapping those in a second Scaffold+AppBar
    // would stack two app bars, so instead of a full outer Scaffold we just
    // put a slim role-switcher TabBar above the selected screen and let that
    // screen's own AppBar render normally underneath it.
    final theme = Theme.of(context);
    return DefaultTabController(
      length: journals.length,
      child: Scaffold(
        body: Column(
          children: [
            Material(
              color: theme.colorScheme.surface,
              elevation: 1,
              child: SafeArea(
                bottom: false,
                child: TabBar(
                  tabs: journals.map((j) => Tab(text: 'Jurnal ${j.$1}')).toList(),
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: journals.map((j) => j.$2).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
