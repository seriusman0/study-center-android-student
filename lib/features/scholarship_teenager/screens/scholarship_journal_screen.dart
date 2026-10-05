import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../college/models/college_journal_model.dart';
import '../providers/scholarship_teenager_journal_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/journal_ui_components.dart';

class ScholarshipJournalScreen extends ConsumerStatefulWidget {
  const ScholarshipJournalScreen({super.key});

  @override
  ConsumerState<ScholarshipJournalScreen> createState() => _ScholarshipJournalScreenState();
}

class _ScholarshipJournalScreenState extends ConsumerState<ScholarshipJournalScreen> {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jurnal Harian'),
        actions: [
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(scholarshipTeenagerJournalProvider.notifier).load()),
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
      if (state.loading) return const Center(child: CircularProgressIndicator());
      if (state.error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
                onPressed: () => ref.read(scholarshipTeenagerJournalProvider.notifier).load(),
              ),
            ]),
          ),
        );
      }
      return const Center(child: Text('Gagal memuat. Tap refresh.', style: TextStyle(color: AppColors.textMuted)));
    }

    final snap = state.snapshot!;
    final notifier = ref.read(scholarshipTeenagerJournalProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      child: _buildContent(context, state, snap, notifier),
    );
  }

  Widget _buildContent(BuildContext context, ScholarshipJournalState state, CollegeJournalSnapshot snap, ScholarshipTeenagerJournalNotifier notifier) {
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
      ..._buildSections(snap, notifier, state.isToday),
      const SizedBox(height: 12),
      _SchPhotoCard(snap: snap, notifier: notifier, state: state),
      JournalSubmitSection(onSubmit: () {}),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      cacheExtent: 300,
      itemBuilder: (_, index) => items[index],
    );
  }

  List<Widget> _buildSections(CollegeJournalSnapshot snap, ScholarshipTeenagerJournalNotifier notifier, bool isToday) {
    final List<Widget> sections = [];
    int sectionIndex = 1;

    // Allah / Pembacaan
    final allahItems = snap.lifeItemsByKategori['allah'] ?? [];
    sections.add(_SchLifeSection(
      kategori: 'allah',
      number: sectionIndex.toString(),
      items: allahItems,
      snap: snap,
      notifier: notifier,
      isToday: isToday,
    ));
    sectionIndex++;

    // Other categories
    for (final entry in snap.lifeItemsByKategori.entries) {
      if (entry.key == 'allah' || entry.key == 'pembacaan') continue;
      sections.add(_SchLifeSection(
        kategori: entry.key,
        number: sectionIndex.toString(),
        items: entry.value,
        snap: snap,
        notifier: notifier,
        isToday: isToday,
      ));
      sectionIndex++;
    }

    return sections;
  }
}

class _SchProgressHeader extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final ScholarshipJournalState state;
  final ScholarshipTeenagerJournalNotifier notifier;

  const _SchProgressHeader({required this.snap, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return JournalHeader(
      userName: 'Test User Edited', // Ideally from user profile
      dateString: _formatDate(snap.date),
      isToday: state.isToday,
      onPrev: () => notifier.goToPrevDay(),
      onNext: state.isToday ? null : () => notifier.goToNextDay(),
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
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Form jurnal hanya bisa diisi pukul ${snap.config.formOpenTime}–${snap.config.formCloseTime}.', style: TextStyle(color: Colors.orange.shade800))),
        ]),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SchLifeSection extends StatelessWidget {
  final String kategori;
  final String number;
  final List<CollegeLifeItem> items;
  final CollegeJournalSnapshot snap;
  final ScholarshipTeenagerJournalNotifier notifier;
  final bool isToday;

  const _SchLifeSection({
    required this.kategori,
    required this.number,
    required this.items,
    required this.snap,
    required this.notifier,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !snap.config.formActive && isToday;
    final isAllah = kategori == 'allah';

    return JournalSectionCard(
      number: number,
      title: _sectionTitle(kategori),
      subtitle: isAllah ? null : 'Opsional — bisa pilih lebih dari satu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAllah) ...[
            const Text('PEMBACAAN ALKITAB', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Text(
              'Hari ke-${snap.bible.dayNo} — ${snap.bible.plText ?? "-"} / ${snap.bible.pbText ?? "-"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: JournalItemBox(
                    child: AppChecklistTile(
                      label: 'Perjanjian Lama',
                      sublabel: snap.bible.plText,
                      checked: snap.bible.plChecked,
                      enabled: !disabled,
                      onChanged: (v) => notifier.checkBible('pl', v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: JournalItemBox(
                    child: AppChecklistTile(
                      label: 'Perjanjian Baru',
                      sublabel: snap.bible.pbText,
                      checked: snap.bible.pbChecked,
                      enabled: !disabled,
                      onChanged: (v) => notifier.checkBible('pb', v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          ...items.map((item) => JournalItemBox(
            child: AppChecklistTile(
              label: item.label,
              checked: item.checked,
              enabled: !disabled,
              onChanged: (v) => notifier.checkLife(item.id, v),
            ),
          )),
        ],
      ),
    );
  }

  static String _sectionTitle(String k) => switch (k) {
        'allah' => 'Allah',
        'kerohanian' => 'Kerohanian',
        'pendidikan' => 'Pendidikan',
        'karakter' => 'Karakter',
        'sidang' => 'Sidang-Sidang Gereja',
        'rohani' => 'Rohani & Pelayanan',
        _ => k.toUpperCase(),
      };
}

class _SchPhotoCard extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final ScholarshipTeenagerJournalNotifier notifier;
  final ScholarshipJournalState state;

  const _SchPhotoCard({required this.snap, required this.notifier, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = snap.fotoBelajarUrl != null && snap.fotoBelajarUrl!.isNotEmpty;
    final isToday = snap.date == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final disabled = !snap.config.formActive && isToday;

    return JournalSectionCard(
      number: '4',
      title: 'Foto Saat Belajar',
      subtitle: '(opsional)',
      child: Column(
        children: [
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
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.card)),
                  child: const Icon(Icons.image, color: AppColors.textMuted, size: 40),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                label: const Text('Hapus Foto', style: TextStyle(color: AppColors.danger)),
                onPressed: disabled ? null : () => notifier.deletePhoto(),
              ),
            ),
          ] else
            AppUploadBox(onTap: disabled ? null : () => _pickImage(context)),
        ],
      ),
    );
  }

  void _pickImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Kamera'), onTap: () => _capture(ImageSource.camera, ctx)),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeri'), onTap: () => _capture(ImageSource.gallery, ctx)),
        ]),
      ),
    );
  }

  void _capture(ImageSource source, BuildContext ctx) async {
    Navigator.pop(ctx);
    final picker = ImagePicker();
    XFile? file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) {
      try {
        await notifier.uploadPhoto(file);
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Foto berhasil diunggah')));
      } catch (e) {
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal unggah: $e')));
      }
    }
  }
}
