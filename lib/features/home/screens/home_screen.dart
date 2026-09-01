import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/models/user_model.dart';
import '../../journal/providers/journal_provider.dart';
import '../../scholarship_teenager/providers/scholarship_teenager_journal_provider.dart';
import '../../college/providers/college_journal_provider.dart';
import '../../../shared/widgets/update_banner.dart';
import '../models/home_model.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      // /jurnal/* (student journal) is role:student-gated on the backend —
      // calling it for a scholarship_teenager-only account just 403s, so
      // gate strictly on isStudent, not the broader hasStudentDashboard
      // (which also covers scholarship_teenager for nav/shell purposes).
      if (user?.isStudent == true) {
        final jState = ref.read(journalProvider);
        if (jState.snapshot == null && !jState.loading) {
          ref.read(journalProvider.notifier).load();
        }
      }
      // Scholarship_teenager journal lives under /scholarship-teenager-jurnal/*
      // — a user can hold this role together with student, so it is loaded
      // independently rather than as an alternative to the block above.
      if (user?.isScholarshipTeenager == true) {
        final sState = ref.read(scholarshipTeenagerJournalProvider);
        if (sState.snapshot == null && !sState.loading) {
          ref.read(scholarshipTeenagerJournalProvider.notifier).load();
        }
      }
      // College journal (/college-jurnal/*) — same reasoning: a college
      // user can also hold student/scholarship_teenager, so load it
      // independently rather than assuming it's the only role.
      if (user?.isCollege == true) {
        final cState = ref.read(collegeJournalProvider);
        if (cState.snapshot == null && !cState.loading) {
          ref.read(collegeJournalProvider.notifier).load();
        }
      }
      final hState = ref.read(homeProvider);
      if (!hState.loading && hState.blogs.isEmpty && hState.laporan == null) {
        ref.read(homeProvider.notifier).load(user?.cabangSlug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user != null && !user.hasStudentDashboard) {
      return _NonStudentHome(user: user);
    }
    return _StudentHome();
  }
}

/// Home tab content for roles without the student journal/laporan flow
/// (admin, mentor, fulltimer, guest, scholarship_teenager, college).
/// Each role's dedicated tools live in their own tabs (see BottomNavShell);
/// this is just a lightweight welcome + shared blog/galeri feed, same as
/// student sees, minus the journal card that only applies to students.
class _NonStudentHome extends ConsumerWidget {
  final UserModel user;
  const _NonStudentHome({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hState = ref.watch(homeProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    String greeting() {
      final h = now.hour;
      if (h < 11) return 'Selamat pagi';
      if (h < 15) return 'Selamat siang';
      if (h < 18) return 'Selamat sore';
      return 'Selamat malam';
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).load(user.cabangSlug),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const UpdateBanner(),
            const SizedBox(height: 8),
            Text('${greeting()},',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
            Text(user.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE, d MMMM yyyy', 'id').format(now),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _roleLabel(user.primaryRole),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            // --- Journal card (college + student roles) ---
            _JournalCard(user: user, theme: theme),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.article, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Artikel Terbaru',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/blog/create'),
                  child: const Text('Tulis'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hState.loading && hState.blogs.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (hState.blogs.isEmpty)
              Text('Belum ada artikel', style: TextStyle(color: Colors.grey[500]))
            else
              ...hState.blogs.map((blog) => _BlogCard(blog: blog, theme: theme)),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.photo_library, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Galeri Kegiatan',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (hState.loading && hState.galeri.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (hState.galeri.isEmpty)
              Text('Belum ada foto kegiatan', style: TextStyle(color: Colors.grey[500]))
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hState.galeri.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) => _GaleriCard(item: hState.galeri[i]),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'mentor':
        return 'Mentor';
      case 'fulltimer':
        return 'Fulltimer';
      case 'scholarship_teenager':
        return 'Beasiswa Remaja';
      case 'college':
        return 'Mahasiswa';
      case 'guest':
        return 'Tamu';
      default:
        return role;
    }
  }
}

class _StudentHome extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends ConsumerState<_StudentHome> {

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(authProvider).user;
    final jState = ref.watch(journalProvider);
    final hState = ref.watch(homeProvider);
    final snap   = jState.snapshot;
    final theme  = Theme.of(context);
    final now    = DateTime.now();

    String greeting() {
      final h = now.hour;
      if (h < 11) return 'Selamat pagi';
      if (h < 15) return 'Selamat siang';
      if (h < 18) return 'Selamat sore';
      return 'Selamat malam';
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(journalProvider.notifier).load(),
            ref.read(homeProvider.notifier).load(user?.cabangSlug),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const UpdateBanner(),
            const SizedBox(height: 8),
            Text(
              '${greeting()},',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              user?.name ?? '',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id').format(now),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),

            const SizedBox(height: 24),

            // QR Code Absensi
            if (user != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.qr_code,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'QR Absensi',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: user.id.toString(),
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (user.cabang != null)
                        Text(
                          user.cabang!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Web-style navigation buttons for multi-role users
            if (user?.isScholarshipTeenager == true) ...[
              AppPrimaryButton(
                label: 'Mulai Isi Jurnal Remaja Beasiswa',
                icon: Icons.edit_document,
                onPressed: () => context.push('/jurnal'),
              ),
              const SizedBox(height: 8),
            ],
            if (user?.isStudent == true) ...[
              AppPrimaryButton(
                label: 'Mulai Isi Jurnal Remaja SC',
                icon: Icons.edit_document,
                onPressed: () => context.push('/jurnal'),
              ),
              const SizedBox(height: 8),
            ],
            if (user?.isCollege == true) ...[
              AppPrimaryButton(
                label: 'Mulai Isi Jurnal College',
                icon: Icons.edit_document,
                onPressed: () => context.push('/jurnal'),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),

            // Unified JURNAL HARI INI Summary
            if (user?.hasJournalAccess == true) ...[
              Builder(
                builder: (ctx) {
                  // Fallback snapshot priority
                  final bool isLoading = jState.loading || 
                                       ref.watch(scholarshipTeenagerJournalProvider).loading || 
                                       ref.watch(collegeJournalProvider).loading;
                  final String? errorMsg = jState.error ?? 
                                         ref.watch(scholarshipTeenagerJournalProvider).error ?? 
                                         ref.watch(collegeJournalProvider).error;
                  final dynamic activeSnap = jState.snapshot ?? 
                                           ref.watch(scholarshipTeenagerJournalProvider).snapshot ?? 
                                           ref.watch(collegeJournalProvider).snapshot;
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.book,
                                  color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'JURNAL HARI INI',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.1),
                              ),
                              const Spacer(),
                              if (isLoading)
                                const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (activeSnap != null) ...[
                            Text(
                              'Hari ke-${activeSnap.bible.dayNo ?? '-'}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text('PERJANJIAN LAMA',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            Text(activeSnap.bible.plPorsi, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Text('PERJANJIAN BARU',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            Text(activeSnap.bible.pbPorsi, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 16),
                            Text('Progress Jadwal Kehidupan',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: activeSnap.totalCount > 0
                                  ? activeSnap.checkedCount / activeSnap.totalCount
                                  : 0,
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 6),
                            Text('${activeSnap.checkedCount}/${activeSnap.totalCount}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[800], fontWeight: FontWeight.bold)),
                          ] else if (errorMsg != null)
                            Text('Gagal memuat jurnal',
                                style: TextStyle(color: Colors.red[400], fontSize: 13))
                          else
                            const Text('Memuat...',
                                style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 12),
            ],

            // Streak
            if (hState.laporan != null && hState.laporan!.streak > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Streak ${hState.laporan!.streak} hari berturut-turut',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Verse reference
            if (snap != null &&
                snap.verseRef != null &&
                snap.verseRef!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote,
                          color: theme.colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hafal Ayat: ',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Text(snap.verseRef!,
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Artikel Terbaru
            Row(
              children: [
                Icon(Icons.article,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Artikel Terbaru',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/blog/create'),
                  child: const Text('Tulis'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hState.loading && hState.blogs.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (hState.blogs.isEmpty)
              Text('Belum ada artikel',
                  style: TextStyle(color: Colors.grey[500]))
            else
              ...hState.blogs
                  .map((blog) => _BlogCard(blog: blog, theme: theme)),

            const SizedBox(height: 24),

            // Galeri Kegiatan
            Row(
              children: [
                Icon(Icons.photo_library,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Galeri Kegiatan',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/galeri'),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hState.loading && hState.galeri.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (hState.galeri.isEmpty)
              Text('Belum ada foto kegiatan',
                  style: TextStyle(color: Colors.grey[500]))
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hState.galeri.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) =>
                      _GaleriCard(item: hState.galeri[i]),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BibleRow extends StatelessWidget {
  final String type;
  final String porsi;
  final bool checked;

  const _BibleRow(this.type, this.porsi, this.checked);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: checked ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text('$type — $porsi',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogPost blog;
  final ThemeData theme;

  const _BlogCard({required this.blog, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/blog/${blog.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (blog.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: blog.image!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: Icon(Icons.article, color: Colors.grey[400]),
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.article,
                      color: theme.colorScheme.primary),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (blog.publishedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(blog.publishedAt!),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                    if (blog.cabangNama != null)
                      Text(
                        blog.cabangNama!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[400]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMM yyyy', 'id').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

/// Compact journal card shown on both student and non-student home screens.
/// Displays the "Jurnal Hari Ini" entry and navigates to /jurnal when tapped.
class _ScholarshipJournalHomeCard extends ConsumerWidget {
  const _ScholarshipJournalHomeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scholarshipTeenagerJournalProvider);
    final snap = state.snapshot;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/jurnal'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.book, color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Jurnal Beasiswa',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (state.loading)
                    const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 12),
              if (snap != null) ...[
                LinearProgressIndicator(
                  value: snap.totalCount > 0
                      ? snap.checkedCount / snap.totalCount
                      : 0,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snap.checkedCount} dari ${snap.totalCount} item selesai',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ] else if (state.error != null)
                Text('Gagal memuat jurnal beasiswa',
                    style: TextStyle(color: Colors.red[400], fontSize: 13))
              else
                const Text('Memuat...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollegeJournalHomeCard extends ConsumerWidget {
  const _CollegeJournalHomeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collegeJournalProvider);
    final snap = state.snapshot;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/jurnal'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Jurnal College',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (state.loading)
                    const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 12),
              if (snap != null) ...[
                LinearProgressIndicator(
                  value: snap.totalCount > 0
                      ? snap.checkedCount / snap.totalCount
                      : 0,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snap.checkedCount} dari ${snap.totalCount} item selesai',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ] else if (state.error != null)
                Text('Gagal memuat jurnal college',
                    style: TextStyle(color: Colors.red[400], fontSize: 13))
              else
                const Text('Memuat...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final UserModel user;
  final ThemeData theme;

  const _JournalCard({required this.user, required this.theme});

  /// Human-readable labels for every journal-eligible role this account
  /// holds. Kept in sync with JournalRouterScreen's own role→journal
  /// mapping so the beranda hint and the actual /jurnal tabs never
  /// disagree about which journals exist for this user.
  List<String> get _journalRoleLabels {
    final labels = <String>[];
    if (user.isCollege) labels.add('College');
    if (user.isScholarshipTeenager) labels.add('Beasiswa');
    if (user.isStudent) labels.add('Student');
    if (labels.isEmpty) labels.add(user.primaryRole);
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final roleLabels = _journalRoleLabels;
    final isMultiJournal = roleLabels.length > 1;
    final subtitle = isMultiJournal
        ? 'Hari ini • ${roleLabels.length} jurnal: ${roleLabels.join(' & ')}'
        : 'Hari ini • ${roleLabels.first}';

    return Semantics(
      label: 'Jurnal Hari Ini',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/jurnal'),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  Icon(Icons.book,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Jurnal Hari Ini',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      color: Colors.grey[400], size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              if (isMultiJournal) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: roleLabels
                      .map((label) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _GaleriCard extends StatelessWidget {
  final GaleriItem item;

  const _GaleriCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: item.fotoUrl,
        width: 140,
        height: 160,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 140,
          color: Colors.grey[200],
          child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 140,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey[400], size: 40),
        ),
      ),
    );
  }
}
