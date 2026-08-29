import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/college_review_model.dart';
import '../providers/college_review_provider.dart';
import 'college_review_detail_screen.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/app_widgets.dart';

class CollegeReviewScreen extends ConsumerStatefulWidget {
  const CollegeReviewScreen({super.key});

  @override
  ConsumerState<CollegeReviewScreen> createState() => _CollegeReviewScreenState();
}

class _CollegeReviewScreenState extends ConsumerState<CollegeReviewScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collegeReviewProvider.notifier).load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collegeReviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Jurnal College'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(collegeReviewProvider.notifier).load(refresh: true)),
        ],
        bottom: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 0,
          titleSpacing: 8,
          title: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari nama / institusi ...',
              hintStyle: const TextStyle(color: Color(0xFF6B7280)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00695C), width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              suffixIcon: state.filterQ != null && state.filterQ!.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(collegeReviewProvider.notifier).setFilters(q: '');
                      },
                    )
                  : null,
            ),
            style: const TextStyle(color: Color(0xFF0F172A)),
            onSubmitted: (v) {
              ref.read(collegeReviewProvider.notifier).setFilters(q: v);
            },
          ),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(CollegeReviewState state) {
    if (state.loading && state.journals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.journals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Coba lagi'), onPressed: () => ref.read(collegeReviewProvider.notifier).load(refresh: true)),
          ]),
        ),
      );
    }

    if (state.journals.isEmpty) {
      return AppEmptyState(
        icon: Icons.fact_check_outlined,
        headline: 'Belum Ada Jurnal',
        subtext: 'Jurnal yang kamu kirimkan akan muncul di halaman ini.',
        ctaLabel: 'Isi Jurnal Sekarang',
        ctaIcon: Icons.edit_note,
        onCta: () => GoRouter.of(context).go('/jurnal'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(collegeReviewProvider.notifier).load(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notif) {
          if (notif is ScrollEndNotification &&
              notif.metrics.extentAfter < 200 &&
              !state.loading &&
              state.currentPage < state.lastPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(collegeReviewProvider.notifier).loadMore();
            });
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.journals.length + (state.currentPage < state.lastPage ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            if (idx == state.journals.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final j = state.journals[idx];
            return _JournalCard(journal: j);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _JournalCard extends StatelessWidget {
  final ScholarshipJournalSummary journal;
  const _JournalCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(journal.status);
    final period = DateFormat('MMMM yyyy', 'id').format(
      DateTime(journal.periodYear, journal.periodMonth),
    );

    return Card(
      child: InkWell(
        onTap: () => GoRouter.of(context).push('/college/review/${journal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.shade100,
                child: Text(_initials(journal.studentName), style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(journal.studentName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(journal.statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(journal.title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (journal.campus != null)
              Text(journal.campus!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
            Text('Periode: $period • Dikirim ${journal.submittedAt ?? "Draft"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
          ]),
        ),
      ),
    );
  }

  static String _initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': case 'accepted': case 'diterima': return Colors.green;
      case 'rejected': case 'ditolak': return Colors.red;
      case 'revision': case 'revisi': return Colors.orange;
      default: return Colors.blueGrey;
    }
  }
}
