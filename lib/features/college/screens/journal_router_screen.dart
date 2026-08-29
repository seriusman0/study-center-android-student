import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sc_student/features/auth/providers/auth_provider.dart';
import 'package:sc_student/features/journal/screens/journal_screen.dart';
import 'package:sc_student/features/scholarship_teenager/screens/scholarship_journal_screen.dart';
import 'college_journal_screen.dart';

/// Role-aware entry point for the "Jurnal" bottom-nav tab.
///
/// - College users → [CollegeJournalScreen] (pembacaan + life items + study logs + Review tab)
/// - Scholarship_teenager users → [ScholarshipJournalScreen] (pembacaan + life items, NO study_log)
/// - Student users → [JournalScreen] (existing student journal)
class JournalRouterScreen extends ConsumerWidget {
  const JournalRouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user?.isCollege ?? false) {
      return const CollegeJournalScreen();
    }
    if (user?.isScholarshipTeenager ?? false) {
      return const ScholarshipJournalScreen();
    }
    return const JournalScreen();
  }
}
