import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/college_journal_model.dart';
import '../providers/college_journal_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/app_widgets.dart';

class CollegeJournalScreen extends ConsumerStatefulWidget {
  const CollegeJournalScreen({super.key});

  @override
  ConsumerState<CollegeJournalScreen> createState() => _CollegeJournalScreenState();
}

class _CollegeJournalScreenState extends ConsumerState<CollegeJournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(collegeJournalProvider);
      if (!state.loading && state.snapshot == null) {
        ref.read(collegeJournalProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collegeJournalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Harian'),
        actions: [
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(collegeJournalProvider.notifier).load()),
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

  Widget _buildBody(BuildContext context, CollegeJournalState state) {
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
              Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Coba lagi'), onPressed: () => ref.read(collegeJournalProvider.notifier).load()),
            ]),
          ),
        );
      }
      return const Center(child: Text('Gagal memuat. Tap refresh.', style: TextStyle(color: Colors.grey)));
    }

    final snap = state.snapshot!;
    final notifier = ref.read(collegeJournalProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      child: _buildContent(context, state, snap, notifier),
    );
  }

  Widget _buildContent(
      BuildContext context,
      CollegeJournalState state,
      CollegeJournalSnapshot snap,
      CollegeJournalNotifier notifier) {
    if (state.loading) {
      // ✅ SKELETON-first: UI renders instantly, data loads async
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const AppSkeletonTile(),
      );
    }
    // ✅ Lazy builder: only renders visible items (jank-free scroll on long checklists)
    final items = <Widget>[
      _ProgressHeader(snap: snap, state: state, theme: Theme.of(context), notifier: notifier),
      const SizedBox(height: 12),
      _FormWindowBanner(snap: snap, state: state),
      _BibleSection(snap: snap, notifier: notifier),
      ...snap.lifeItemsByKategori.entries.map((entry) => _LifeSection(
          kategori: entry.key,
          items: entry.value,
          snap: snap,
          notifier: notifier,
          isToday: state.isToday,
      )),
      const SizedBox(height: 12),
      _PhotoCard(snap: snap, notifier: notifier, state: state),
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      cacheExtent: 300,
      itemBuilder: (_, index) => items[index],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final CollegeJournalState state;
  final ThemeData theme;
  final CollegeJournalNotifier notifier;

  const _ProgressHeader({required this.snap, required this.state, required this.theme, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final progress = snap.totalCount > 0 ? snap.checkedCount / snap.totalCount : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Jurnal ${_formatDate(snap.date)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white))),
          _NavBtn(icon: Icons.chevron_left, onTap: () => notifier.goToPrevDay()),
          const SizedBox(width: 4),
          _NavBtn(icon: Icons.chevron_right, onTap: state.isToday ? null : () => notifier.goToNextDay()),
          if (!state.isToday) ...[const SizedBox(width: 4),
            GestureDetector(onTap: () => notifier.goToToday(), child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(8)),
              child: const Text('Hari ini', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            )),
          ],
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: progress, minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047))),
        ),
        const SizedBox(height: 8),
        Text('${snap.checkedCount} dari ${snap.totalCount} item selesai',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 8),
        Text('Streak ${snap.streak} hari berturut-turut',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFFDE047), fontWeight: FontWeight.w600)),
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
    return GestureDetector(onTap: onTap, child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: disabled ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: disabled ? Colors.white.withOpacity(0.3) : Colors.white, size: 20),
    ));
  }
}

class _FormWindowBanner extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final CollegeJournalState state;
  const _FormWindowBanner({required this.snap, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (state.isToday && !snap.config.formActive) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Form jurnal hanya bisa diisi pukul ${snap.config.formOpenTime.substring(0, 5)}–${snap.config.formCloseTime.substring(0, 5)}.',
              style: TextStyle(color: Colors.orange.shade800))),
        ]),
      );
    }
    return const SizedBox.shrink();
  }
}

class _BibleSection extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final CollegeJournalNotifier notifier;

  const _BibleSection({required this.snap, required this.notifier});

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

    String? subtitle;
    if (snap.bible.plText.isNotEmpty || snap.bible.pbText.isNotEmpty) {
      subtitle =
          'Hari ke-${snap.bible.dayNo} — ${snap.bible.plText} / ${snap.bible.pbText}';
    } else {
      subtitle = 'Jadwal hari ke-${snap.bible.dayNo} belum diisi admin.';
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.xs, bottom: AppSpacing.xs),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          AppSectionCard(
            title: 'Pembacaan Alkitab',
            rows: rows,
          ),
        ],
      ),
    );
  }
}

class _LifeSection extends StatelessWidget {
  final String kategori;
  final List<CollegeLifeItem> items;
  final CollegeJournalSnapshot snap;
  final CollegeJournalNotifier notifier;
  final bool isToday;

  const _LifeSection({
    required this.kategori,
    required this.items,
    required this.snap,
    required this.notifier,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final title = _sectionTitle(kategori);
    final disabled = !snap.config.formActive && isToday;

    final rows = <Widget>[
      for (final item in items) _buildItem(context, item, snap, notifier, disabled),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppSectionCard(
        title: title,
        rows: rows,
      ),
    );
  }

  Widget _buildItem(BuildContext context, CollegeLifeItem item, CollegeJournalSnapshot snap, CollegeJournalNotifier notifier, bool disabled) {
    final studyLog = snap.studyLogs[item.id];
    final hasStudy = studyLog != null && studyLog.jamMulai.isNotEmpty && studyLog.jamSelesai.isNotEmpty;

    switch (item.responseType) {
      case CollegeItemResponseType.check:
        return AppChecklistTile(
          label: item.label,
          checked: item.checked,
          enabled: !disabled,
          onChanged: (v) => notifier.checkLife(item.id, v),
        );
      case CollegeItemResponseType.boolean:
        return AppChecklistTile(
          label: item.label,
          checked: item.checked,
          enabled: !disabled,
          onChanged: (v) => notifier.toggleBoolean(item.id, v),
        );
      case CollegeItemResponseType.timeRange:
        return _TimeRangeItem(
          item: item,
          snap: snap,
          isEnabled: !disabled,
          onTap: () => _openTimeRangePicker(context, item, snap, notifier),
        );
      case CollegeItemResponseType.unknown:
        return AppChecklistTile(
          label: item.label,
          checked: item.checked,
          enabled: !disabled,
          onChanged: (v) => notifier.checkLife(item.id, v),
        );
    }
  }

  void _openTimeRangePicker(BuildContext context, CollegeLifeItem item, CollegeJournalSnapshot snap, CollegeJournalNotifier notifier) {
    final existing = snap.studyLogs[item.id];
    final startCtrl = TextEditingController(text: existing?.jamMulai ?? '');
    final endCtrl = TextEditingController(text: existing?.jamSelesai ?? '');
    final tipeCtrl = TextEditingController(text: existing?.tipe ?? 'mandiri');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => LayoutBuilder(
        builder: (ctx, constraints) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              width: constraints.maxWidth,
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(item.label, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _TimeField(label: 'Jam Mulai', controller: startCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _TimeField(label: 'Jam Selesai', controller: endCtrl)),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipeCtrl.text.isEmpty ? 'mandiri' : tipeCtrl.text,
                  items: const [
                    DropdownMenuItem(value: 'mandiri', child: Text('Mandiri')),
                    DropdownMenuItem(value: 'kelompok', child: Text('Kelompok')),
                  ],
                  onChanged: (v) => tipeCtrl.text = v ?? 'mandiri',
                  decoration: const InputDecoration(labelText: 'Tipe', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      final jm = startCtrl.text;
                      final js = endCtrl.text;
                      if (jm.isNotEmpty && js.isNotEmpty) {
                        await notifier.saveStudyLog(item.id, jm, js, tipeCtrl.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } else if (jm.isEmpty && js.isEmpty) {
                        await notifier.saveStudyLog(item.id, '', '', tipeCtrl.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Simpan'),
                  )),
                ]),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  static String _sectionTitle(String k) => switch (k) {
        'pembacaan' => 'Item Pembacaan',
        'sidang' => 'Sidang-Sidang Gereja',
        'rohani' => 'Kegiatan Rohani',
        _ => k.toUpperCase(),
      };
}

class _TimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _TimeField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), hintText: 'HH:MM'),
      onTap: () async {
        final now = TimeOfDay.now();
        final picked = await showTimePicker(context: context, initialTime: now);
        if (picked != null) controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      },
    );
  }
}

class _TimeRangeItem extends StatelessWidget {
  final CollegeLifeItem item;
  final CollegeJournalSnapshot snap;
  final bool isEnabled;
  final VoidCallback onTap;
  const _TimeRangeItem({required this.item, required this.snap, required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final studyLog = snap.studyLogs[item.id];
    final hasValue = studyLog != null && studyLog.jamMulai.isNotEmpty && studyLog.jamSelesai.isNotEmpty;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: !isEnabled ? Colors.grey[50] : (hasValue ? Colors.teal.shade50 : null),
        ),
        child: Row(children: [
          Icon(Icons.access_time, size: 18, color: isEnabled ? Colors.teal : Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(child: Text(
            item.label,
            style: TextStyle(color: isEnabled ? Colors.black87 : Colors.grey[400], fontWeight: FontWeight.w500),
          )),
          if (hasValue) ...[
            Text('${studyLog.jamMulai}—${studyLog.jamSelesai}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
          ],
        ]),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final CollegeJournalSnapshot snap;
  final CollegeJournalNotifier notifier;
  final CollegeJournalState state;

  const _PhotoCard({required this.snap, required this.notifier, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = snap.fotoBelajarUrl != null && snap.fotoBelajarUrl!.isNotEmpty;
    final isToday = snap.date == DateFormat('yyyy-MM-dd').format(DateTime.now());
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
      file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
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

class _UploadPrompt extends StatelessWidget {
  final bool disabled;
  final VoidCallback? onTap;
  const _UploadPrompt({this.disabled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppUploadBox(
      mainText: disabled ? 'Tidak dapat mengunggah' : 'Ketuk untuk tambah foto',
      helperText: disabled ? null : 'Format JPG/PNG, maks. 5MB',
      onTap: disabled ? null : onTap,
    );
  }
}
