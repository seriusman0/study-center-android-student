import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sc_student/features/auth/providers/auth_provider.dart';
import 'package:sc_student/features/auth/models/user_model.dart';
import 'package:sc_student/features/journal/screens/journal_screen.dart';
import 'package:sc_student/features/scholarship_teenager/screens/scholarship_journal_screen.dart';
import 'college_journal_screen.dart';
import '../../../shared/theme/design_tokens.dart';

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
  final String? initialTab;
  const JournalRouterScreen({super.key, this.initialTab});

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
      entries.add(('Jurnal', const JournalScreen()));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final journals = _journalsFor(user);

    if (journals.length == 1) {
      return journals.first.$2;
    }

    int initIndex = 0;
    if (initialTab != null) {
      initIndex = journals.indexWhere((j) => j.$1 == initialTab);
      if (initIndex < 0) initIndex = 0;
    }

    final theme = Theme.of(context);
    return DefaultTabController(
      length: journals.length,
      initialIndex: initIndex,
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
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: journals.map((j) {
                  return KeyedSubtree(
                    key: PageStorageKey<String>('journal_tab_${j.$1}'),
                    // MediaQuery.sizeOf untuk mendapat ukuran layar aktual,
                    // bukan dari constraint TabBarView (yang bisa unbounded
                    // saat animasi transisi tab → menyebabkan cascade crash
                    // "BoxConstraints forces an infinite width" di child
                    // yang punya DropdownButtonFormField / ElevatedButton).
                    child: Builder(
                      builder: (ctx) {
                        final size = MediaQuery.sizeOf(ctx);
                        return SizedBox(
                          width: size.width,
                          height: size.height,
                          child: j.$2,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
