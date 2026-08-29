import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../college/models/college_journal_model.dart';
import '../providers/scholarship_teenager_journal_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Jurnal harian untuk role scholarship_teenager.
///
/// Mirip [CollegeJournalScreen] dengan perbedaan:
/// - Endpoint: /api/scholarship-teenager-jurnal/today & /check
/// - TIDAK ada study_log (time_range) — hanya check & boolean
/// - Section: Pembacaan Alkitab (PL/PB), lalu life_items per-kategori
///   (pembacaan, sidang, rohani), lalu Foto Belajar
/// - formOpen lock via config.form_active
class ScholarshipJournalScreen extends ConsumerStatefulWidget {
  const ScholarshipJournalScreen({super.key});

  @override
  ConsumerState<ScholarshipJournalScreen> createState() =>
      _ScholarshipJournalScreenState();
}

class _ScholarshipJournalScreenState
    extends ConsumerState<ScholarshipJournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final st = ref.read(scholarshipTeenagerJournalProvider);
      if (!st.loading && st.snapshot == null) {
        ref.read(scholarshipTeenagerJournalProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scholarshipTeenagerJournalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Harian'),
        actions: [
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
                onPressed: () =>
                    ref.read(scholarshipTeenagerJournalProvider.notifier).load()),
          if (state.pendingOfflineOps > 0 && state.isOnline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Icon(Icons.sync, size: 20)),
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ScholarshipJournalState state) {
    if (state.snapshot == null) {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }
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
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                  onPressed: () =>
                      ref.read(scholarshipTeenagerJournalProvider.notifier).load()),
            ]),
          ),
        );
      }
      return const Center(
          child: Text('Gagal memuat. Tap refresh.',
              style: TextStyle(color: Colors.grey)));
    }

    final snap = state.snapshot!;
    final notifier = ref.read(scholarshipTeenagerJournalProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      child: _buildContent(context, state, snap, notifier),
    );
  }

  Widget _buildContent(
      BuildContext context,
      ScholarshipJournalState state,
      CollegeJournalSnapshot snap,
      ScholarshipTeenagerJournalNotifier notifier) {
    if (state.loading) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const AppSkeletonTile(),
      );
    }

    final items = <Widget>[
      _SchProgressHeader(snap: snap, state: state, notifier: notifier),
      const SizedBox(height: 12),
      _SchFormWindowBanner(snap: snap, state: state),
      _SchBibleSection(snap: snap, notifier: notifier),
      ...snap.lifeItemsByKategori.entries.map((entry) => _SchLifeSection(
            kategori: entry.key,
            items: entry.value,
            snap: snap,
            notifier: notifier,
            isToday: state.isToday,
          )),
      const SizedBox(height: 12),
      _SchPhotoCard(snap: snap, notifier: notifier, state: state),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      cacheExtent: 300,
      itemBuilder: (_, index) => items[index],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress header (date nav + streak)
// ─────────────────────────────────────────────────────────────────────────────

class _SchProgressHeader extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final ScholarshipJournalState state;
  final ScholarshipTeenagerJournalNotifier notifier;

  const _SchProgressHeader(
      {required this.snap, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        snap.totalCount > 0 ? snap.checkedCount / snap.totalCount : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('Jurnal ${_formatDate(snap.date)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white))),
          _NavBtn(icon: Icons.chevron_left, onTap: () => notifier.goToPrevDay()),
          const SizedBox(width: 4),
          _NavBtn(
              icon: Icons.chevron_right,
              onTap: state.isToday ? null : () => notifier.goToNextDay()),
          if (!state.isToday) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => notifier.goToToday(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF97316),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Hari ini',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047))),
        ),
        const SizedBox(height: 8),
        Text('${snap.checkedCount} dari ${snap.totalCount} item selesai',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 8),
        Text('Streak ${snap.streak} hari berturut-turut',
            style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFFDE047),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.parse(date));
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
          child: Icon(icon,
              color: disabled
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white,
              size: 20),
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form window banner (locked outside form hours)
// ─────────────────────────────────────────────────────────────────────────────

class _SchFormWindowBanner extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final ScholarshipJournalState state;
  const _SchFormWindowBanner({required this.snap, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isToday && !snap.config.formActive) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200)),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  'Form jurnal hanya bisa diisi pukul ${snap.config.formOpenTime.substring(0, 5)}–${snap.config.formCloseTime.substring(0, 5)}.',
                  style: TextStyle(color: Colors.orange.shade800))),
        ]),
      );
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bible section (PL/PB checkboxes)
// ─────────────────────────────────────────────────────────────────────────────

class _SchBibleSection extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final ScholarshipTeenagerJournalNotifier notifier;
  const _SchBibleSection({required this.snap, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final disabled = !snap.config.formActive;

    final rows = <Widget>[
      AppChecklistTile(
        label: 'Perjanjian Lama',
        checked: snap.bible.plChecked,
        enabled: !disabled,
        onChanged: (v) => notifier.checkBible('pl', v),
      ),
      AppChecklistTile(
        label: 'Perjanjian Baru',
        checked: snap.bible.pbChecked,
        enabled: !disabled,
        onChanged: (v) => notifier.checkBible('pb', v),
      ),
    ];

    final subtitle = (snap.bible.plText.isNotEmpty || snap.bible.pbText.isNotEmpty)
        ? 'Hari ke-${snap.bible.dayNo} — ${snap.bible.plText} / ${snap.bible.pbText}'
        : 'Jadwal hari ke-${snap.bible.dayNo} belum diisi admin.';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
        AppSectionCard(title: 'Pembacaan Alkitab', rows: rows),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Life items per-kategori (check/boolean only — no time_range)
// ─────────────────────────────────────────────────────────────────────────────

class _SchLifeSection extends StatelessWidget {
  final String kategori;
  final List<CollegeLifeItem> items;
  final CollegeJournalSnapshot snap;
  final ScholarshipTeenagerJournalNotifier notifier;
  final bool isToday;

  const _SchLifeSection({
    required this.kategori,
    required this.items,
    required this.snap,
    required this.notifier,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !snap.config.formActive && isToday;

    final rows = <Widget>[
      for (final item in items) _buildItem(item, disabled),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppSectionCard(title: _sectionTitle(kategori), rows: rows),
    );
  }

  Widget _buildItem(CollegeLifeItem item, bool disabled) {
    // scholarship_teenager has no time_range items — treat everything as check
    return AppChecklistTile(
      label: item.label,
      checked: item.checked,
      enabled: !disabled,
      onChanged: (v) => notifier.checkLife(item.id, v),
    );
  }

  static String _sectionTitle(String k) => switch (k) {
        'pembacaan' => 'Item Pembacaan',
        'sidang' => 'Sidang-Sidang Gereja',
        'rohani' => 'Kegiatan Rohani & Pelayanan',
        _ => k.toUpperCase(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Foto belajar card
// ─────────────────────────────────────────────────────────────────────────────

class _SchPhotoCard extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final ScholarshipTeenagerJournalNotifier notifier;
  final ScholarshipJournalState state;

  const _SchPhotoCard(
      {required this.snap, required this.notifier, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        snap.fotoBelajarUrl != null && snap.fotoBelajarUrl!.isNotEmpty;
    final isToday =
        snap.date == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final disabled = !snap.config.formActive && isToday;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppSectionCard(
        title: 'Foto Belajar',
        rows: [
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Image.network(
                snap.fotoBelajarUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Icon(Icons.image,
                      color: AppColors.textMuted, size: 40),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 18),
                label: const Text('Hapus Foto',
                    style: TextStyle(color: AppColors.danger)),
                onPressed: disabled ? null : () => notifier.deletePhoto(),
              ),
            ),
          ] else
            AppUploadBox(
              onTap: disabled ? null : () => _pickImage(context),
            ),
        ],
      ),
    );
  }

  void _pickImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kamera'),
            onTap: () => _capture(ImageSource.camera, ctx),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeri'),
            onTap: () => _capture(ImageSource.gallery, ctx),
          ),
        ]),
      ),
    );
  }

  void _capture(ImageSource source, BuildContext ctx) async {
    Navigator.pop(ctx);
    final picker = ImagePicker();
    XFile? file;
    if (source == ImageSource.camera) {
      file = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 85);
    } else {
      file = await picker.pickImage(source: ImageSource.gallery);
    }
    if (file != null) {
      try {
        await notifier.uploadPhoto(file);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Foto berhasil diunggah')),
          );
        }
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Gagal unggah: $e')),
          );
        }
      }
    }
  }
}
