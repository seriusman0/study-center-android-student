import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../models/journal_model.dart';
import '../providers/journal_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/app_widgets.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

/// Wraps a child with a try-catch so layout-time exceptions don't blank the
/// whole screen. On error, displays a readable stack trace and a Retry
/// button so the user can recover.
class _JournalErrorBoundary extends StatefulWidget {
  final Widget child;
  const _JournalErrorBoundary({required this.child});

  @override
  State<_JournalErrorBoundary> createState() => _JournalErrorBoundaryState();
}

class _JournalErrorBoundaryState extends State<_JournalErrorBoundary> {
  FlutterErrorDetails? _error;
  void Function(FlutterErrorDetails)? _previousHandler;

  @override
  void initState() {
    super.initState();
    // Save the previous handler so we can restore it on dispose, instead of
    // permanently overwriting FlutterError.onError for the whole app.
    _previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      // Always forward to the previous handler (typically main.dart's
      // debugPrint-based logger) so the FULL stack trace is preserved in
      // adb logcat even after we've captured it for the UI.
      _previousHandler?.call(details);
      // Defer state change to after the frame — synchronous setState() during
      // a build phase would re-enter this same handler and re-trigger the
      // MouseTracker assertion we're trying to recover from.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _error = details);
        }
      });
    };
  }

  @override
  void dispose() {
    // Restore the previous handler so other widgets/screens aren't affected.
    if (_previousHandler != null) {
      FlutterError.onError = _previousHandler;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final e = _error!;
      final stack = e.stack?.toString() ?? 'no stack';
      return Container(
        color: const Color(0xFFFEE2E2),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // stretch memastikan semua children (termasuk ElevatedButton)
            // mendapat bounded width dari parent — tanpa ini Column.min
            // memberikan unbounded width ke ElevatedButton sehingga crash
            // "BoxConstraints forces an infinite width".
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Icon(Icons.error_outline, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Jurnal Error',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ]),
              const SizedBox(height: 8),
              Text(e.exceptionAsString(),
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 8),
              if (e.context != null)
                Text('Context: ${e.context}',
                    style: const TextStyle(
                        color: Colors.red, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(stack,
                    style: const TextStyle(
                        fontSize: 10, fontFamily: 'monospace')),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() => _error = null),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jState = ref.read(journalProvider);
      if (!jState.loading && jState.snapshot == null) {
        ref.read(journalProvider.notifier).load();
      }
      final hState = ref.read(homeProvider);
      if (!hState.loading && hState.laporan == null) {
        final user = ref.read(authProvider).user;
        ref.read(homeProvider.notifier).load(user?.cabangSlug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Harian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat',
            onPressed: () => context.push('/journal/history'),
          ),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(journalProvider.notifier).load(),
            ),
        ],
      ),
      body: _JournalErrorBoundary(
        // Bungkus dengan SizedBox menggunakan MediaQuery.size untuk memastikan
        // semua children (termasuk DropdownButtonFormField dan ElevatedButton
        // di _HafalAyatSection) selalu mendapat bounded width constraint.
        // Tanpa ini, saat JournalScreen pertama kali dirender dalam TabBarView
        // atau page route animation, Scaffold body bisa mendapat w=Infinity
        // → cascade crash "BoxConstraints forces an infinite width".
        child: _buildBody(context, state, theme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JournalState state, ThemeData theme) {
    if (state.snapshot == null) {
      if (state.error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(journalProvider.notifier).load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ]),
          ),
        );
      }
      if (state.loading) {
        // Loading spinner — jangan blank screen.
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat jurnal…', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        );
      }
      // snapshot == null && !loading && error == null → belum ada data / gagal diam-diam.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Belum ada data. Tap refresh.',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(journalProvider.notifier).load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final snap = state.snapshot!;
    final notifier = ref.read(journalProvider.notifier);
    final streak = ref.watch(homeProvider).laporan?.streak;

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 4,
        cacheExtent: 300,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return _ProgressHeader(
                checked: snap.checkedCount,
                total: snap.totalCount,
                date: snap.date,
                streak: streak,
                isToday: state.isToday,
                onPrev: () => notifier.goToPrevDay(),
                onNext: state.isToday ? null : () => notifier.goToNextDay(),
                onToday: state.isToday ? null : () => notifier.goToToday(),
              );
            case 1:
              return _LifeScheduleCard(snap: snap, notifier: notifier);
            case 2:
              return const SizedBox(height: 12);
            case 3:
              return _PhotoCard(snap: snap, notifier: notifier);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int checked;
  final int total;
  final String date;
  final int? streak;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  const _ProgressHeader({
    required this.checked,
    required this.total,
    required this.date,
    this.streak,
    required this.isToday,
    required this.onPrev,
    this.onNext,
    this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? checked / total : 0.0;
    final formatted = _formatDate(date);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              'Jurnal $formatted',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          // Date navigation buttons
          _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
          const SizedBox(width: 4),
          _NavBtn(icon: Icons.chevron_right, onTap: onNext),
          if (onToday != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onToday,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Hari ini',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$checked/$total',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ]),
        if (streak != null && streak! > 0) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Streak $streak hari berturut-turut',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFDE047),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ]),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('EEEE, d MMMM yyyy', 'id').format(dt);
    } catch (_) {
      return date;
    }
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: disabled ? Colors.white.withOpacity(0.3) : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _LifeScheduleCard extends StatelessWidget {
  final JournalSnapshot snap;
  final JournalNotifier notifier;

  const _LifeScheduleCard({required this.snap, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final byKategori = snap.lifeItemsByKategori;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        // stretch so _HafalAyatSection (with DropdownButtonFormField + ElevatedButton)
        // always receives bounded width constraints and never triggers
        // BoxConstraints(w=Infinity) layout errors.
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: primary, borderRadius: BorderRadius.circular(8)),
              child: const Center(
                  child: Text('1',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13))),
            ),
            const SizedBox(width: 8),
            Text('Jadwal Kehidupan',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          for (final entry in byKategori.entries) ...[
            const SizedBox(height: 8),
            Text(
              _kategoriLabel(entry.key),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (entry.key == 'kerohanian') ...[
              _BibleReadingInline(snap: snap, notifier: notifier),
              _HafalAyatSection(snap: snap, notifier: notifier),
            ],
            for (final item in entry.value)
              _CheckRow(
                label: item.label,
                checked: item.checked,
                onTap: () => notifier.checkLife(item.id, !item.checked),
              ),
          ],
        ]),
      ),
    );
  }

  String _kategoriLabel(String k) {
    switch (k) {
      case 'kerohanian':
        return 'KEROHANIAN';
      case 'pendidikan':
        return 'PENDIDIKAN';
      case 'karakter':
        return 'KARAKTER';
      default:
        return k.toUpperCase();
    }
  }
}

class _BibleReadingInline extends StatelessWidget {
  final JournalSnapshot snap;
  final JournalNotifier notifier;
  const _BibleReadingInline({required this.snap, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Baca Alkitab',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (snap.bible.dayNo != null)
                Text(
                  ' — Hari ke-${snap.bible.dayNo}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _CheckRow(
            label: 'Perjanjian Lama',
            subtitle: snap.bible.plText?.isNotEmpty == true
                ? snap.bible.plText
                : (snap.bible.plPorsi.isNotEmpty ? snap.bible.plPorsi : null),
            checked: snap.bible.plChecked,
            onTap: () => notifier.checkBible('pl', !snap.bible.plChecked),
          ),
          _CheckRow(
            label: 'Perjanjian Baru',
            subtitle: snap.bible.pbText?.isNotEmpty == true
                ? snap.bible.pbText
                : (snap.bible.pbPorsi.isNotEmpty ? snap.bible.pbPorsi : null),
            checked: snap.bible.pbChecked,
            onTap: () => notifier.checkBible('pb', !snap.bible.pbChecked),
          ),
        ],
      ),
    );
  }
}

// ── Hafal Ayat Section ────────────────────────────────────────────────────────
// Menampilkan dua bagian:
//   a) Input/display teks ayat (verse_ref) — shared per-minggu
//   b) Checkbox per-hari (verseChecked) — hanya bisa dicentang jika verse_ref sudah ada

class _HafalAyatSection extends StatefulWidget {
  final JournalSnapshot snap;
  final JournalNotifier notifier;
  const _HafalAyatSection({required this.snap, required this.notifier});

  @override
  State<_HafalAyatSection> createState() => _HafalAyatSectionState();
}

const _bibleBooks = [
  'Kejadian',
  'Keluaran',
  'Imamat',
  'Bilangan',
  'Ulangan',
  'Yosua',
  'Hakim-hakim',
  'Rut',
  '1 Samuel',
  '2 Samuel',
  '1 Raja-raja',
  '2 Raja-raja',
  '1 Tawarikh',
  '2 Tawarikh',
  'Ezra',
  'Nehemia',
  'Ester',
  'Ayub',
  'Mazmur',
  'Amsal',
  'Pengkhotbah',
  'Kidung Agung',
  'Yesaya',
  'Yeremia',
  'Ratapan',
  'Yehezkiel',
  'Daniel',
  'Hosea',
  'Yoel',
  'Amos',
  'Obaja',
  'Yunus',
  'Mikha',
  'Nahum',
  'Habakuk',
  'Zefanya',
  'Hagai',
  'Zakharia',
  'Maleakhi',
  'Matius',
  'Markus',
  'Lukas',
  'Yohanes',
  'Kisah Para Rasul',
  'Roma',
  '1 Korintus',
  '2 Korintus',
  'Galatia',
  'Efesus',
  'Filipi',
  'Kolose',
  '1 Tesalonika',
  '2 Tesalonika',
  '1 Timotius',
  '2 Timotius',
  'Titus',
  'Filemon',
  'Ibrani',
  'Yakobus',
  '1 Petrus',
  '2 Petrus',
  '1 Yohanes',
  '2 Yohanes',
  '3 Yohanes',
  'Yudas',
  'Wahyu'
];

class _HafalAyatSectionState extends State<_HafalAyatSection> {
  String? _selectedKitab;
  late final TextEditingController _pasal;
  late final TextEditingController _ayat;
  String _savedLabel = '';

  @override
  void initState() {
    super.initState();
    final ref = widget.snap.verseRef ?? '';
    final parsed = _parseRef(ref);
    _selectedKitab = parsed.$1.isNotEmpty && _bibleBooks.contains(parsed.$1)
        ? parsed.$1
        : null;
    _pasal = TextEditingController(text: parsed.$2);
    _ayat = TextEditingController(text: parsed.$3);
    _savedLabel = ref;
  }

  @override
  void didUpdateWidget(_HafalAyatSection old) {
    super.didUpdateWidget(old);
    final newRef = widget.snap.verseRef ?? '';
    if (newRef != _savedLabel && newRef.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectedKitab = null;
          _pasal.clear();
          _ayat.clear();
          setState(() => _savedLabel = '');
        }
      });
    }
  }

  (String, String, String) _parseRef(String ref) {
    final m = RegExp(r'^(.+?)\s+(\d+):(\d+)$').firstMatch(ref);
    if (m != null) return (m.group(1)!, m.group(2)!, m.group(3)!);
    return ('', '', '');
  }

  Future<void> _save() async {
    final k = _selectedKitab ?? '';
    final p = _pasal.text.trim();
    final a = _ayat.text.trim();
    if (k.isEmpty || p.isEmpty || a.isEmpty) return;
    final ref = '$k $p:$a';
    if (ref == _savedLabel) return;
    _savedLabel = ref;
    await widget.notifier.saveVerseRef(ref);
    if (mounted) setState(() {});
  }

  Future<void> _clear() async {
    _selectedKitab = null;
    _pasal.clear();
    _ayat.clear();
    _savedLabel = '';
    await widget.notifier.saveVerseRef(null);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pasal.dispose();
    _ayat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = _selectedKitab != null ||
        _pasal.text.isNotEmpty ||
        _ayat.text.isNotEmpty;
    final theme = Theme.of(context);
    final hint = widget.snap.bible.collegePorsiHint;
    final verseRef = widget.snap.verseRef ?? '';
    final hasVerseRef = verseRef.isNotEmpty;
    final verseChecked = widget.snap.verseChecked;

    // Subtitle untuk checkbox: potong teks ayat jika > 50 char
    final verseSubtitle = hasVerseRef
        ? (verseRef.length > 50 ? '${verseRef.substring(0, 47)}…' : verseRef)
        : null;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // LayoutBuilder memastikan kita tahu lebar aktual saat ini.
        // Jika constraint unbounded (terjadi saat page route animation
        // atau TabBarView render pertama kali), fallback ke MediaQuery.
        final safeWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(ctx).size.width;
        return SizedBox(
          width: safeWidth,
          child: _buildHafalAyatContent(ctx, hasInput, hasVerseRef, verseRef, verseSubtitle, verseChecked, hint, theme),
        );
      },
    );
  }

  Widget _buildHafalAyatContent(BuildContext context, bool hasInput, bool hasVerseRef, String verseRef, String? verseSubtitle, bool verseChecked, String hint, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(12),
      ),
      // stretch so Dropdown/TextField/ElevatedButton always get bounded width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          const Text('Hafal Ayat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),

          // ── (a) Checkbox per-hari ────────────────────────────────────────────
          AppChecklistTile(
            label: 'Hafal hari ini',
            sublabel: verseSubtitle,
            checked: verseChecked,
            onChanged: (_) async {
              if (!hasVerseRef) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Isi teks ayat terlebih dahulu'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                return;
              }
              await widget.notifier.checkVerseChecked(!verseChecked);
            },
          ),

          const Divider(height: 20),

          // ── (b) Input/display teks ayat (verse_ref) per-minggu ──────────────
          Text(
            hint.isNotEmpty
                ? 'Dari porsi hari ini: $hint'
                : 'Pilih satu ayat dari porsi bacaan hari ini.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedKitab,
            decoration: _inputDeco('Pilih Kitab'),
            isExpanded: true,
            menuMaxHeight: 300,
            items: _bibleBooks
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedKitab = val);
            },
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Semantics(
                identifier: 'pasalInput',
                child: TextField(
                  controller: _pasal,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDeco('Pasal'),
                  onEditingComplete: _save,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                identifier: 'ayatInput',
                child: TextField(
                  controller: _ayat,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDeco('Ayat'),
                  onEditingComplete: _save,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          // Gunakan struktur Row yang aman:
          // - Label tersimpan: Expanded agar tidak overflow
          // - Tombol: dibungkus Row di dalam Flexible agar tidak infinite width
          // Catatan: JANGAN gunakan Row(spaceBetween) + Row.min(ElevatedButton)
          // tanpa Flexible — menyebabkan BoxConstraints infinite width.
          Row(children: [
            // Sisi kiri: label tersimpan atau spacer
            if (_savedLabel.isNotEmpty)
              Expanded(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('Tersimpan: $_savedLabel',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success, fontWeight: FontWeight.w500)),
                  ),
                ]),
              )
            else
              const Expanded(child: SizedBox.shrink()),
            // Sisi kanan: tombol Hapus dan/atau Simpan — dibungkus Flexible
            // supaya ElevatedButton selalu mendapat bounded width constraint.
            Flexible(
              fit: FlexFit.loose,
              // OverflowBar menangani button layout secara proper,
              // termasuk ketika mendapat constraint unbounded.
              child: OverflowBar(
                spacing: 8,
                children: [
                  if (hasInput)
                    TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Hapus'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (!hasInput || _savedLabel.isEmpty)
                    ElevatedButton(
                      onPressed: hasInput ? _save : null,
                      style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                      child: const Text('Simpan'),
                    ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderStrong),
        ),
      );
}

class _CheckRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool checked;
  final VoidCallback onTap;

  const _CheckRow(
      {required this.label,
      this.subtitle,
      required this.checked,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppChecklistTile(
      label: label,
      sublabel: subtitle,
      checked: checked,
      onChanged: (_) => onTap(),
    );
  }
}

class _PhotoCard extends StatefulWidget {
  final JournalSnapshot snap;
  final JournalNotifier notifier;

  const _PhotoCard({required this.snap, required this.notifier});

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() => _uploading = true);
      await widget.notifier.uploadPhoto(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto?'),
        content: const Text('Yakin ingin menghapus foto ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _uploading = true);
      try {
        await widget.notifier.deletePhoto();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        widget.snap.photoUrl != null && widget.snap.photoUrl!.isNotEmpty;

    return AppSectionCard(
      title: 'Foto Saat Belajar (opsional)',
      rows: [
        if (hasPhoto)
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Image.network(
                  widget.snap.photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.border,
                    child: const Icon(Icons.broken_image,
                        color: AppColors.textMuted, size: 48),
                  ),
                ),
              ),
              if (_uploading) const CircularProgressIndicator(),
            ],
          ),
        AppUploadBox(
          mainText: hasPhoto ? 'Ganti Foto' : 'Upload Foto',
          onTap: _uploading ? null : _pickAndUpload,
        ),
        if (hasPhoto)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _uploading ? null : _removePhoto,
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger, size: 18),
              label: const Text('Hapus',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ),
      ],
    );
  }
}
