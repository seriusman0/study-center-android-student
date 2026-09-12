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
      return const Center(child: Text('Gagal memuat. Tap refresh.', style: TextStyle(color: AppColors.textMuted)));
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
    
    final pembacaanItems = snap.lifeItemsByKategori['pembacaan'] ?? [];
    final otherKategoriEntries = snap.lifeItemsByKategori.entries.where((e) => e.key != 'pembacaan');

    // ✅ Lazy builder: only renders visible items (jank-free scroll on long checklists)
    final items = <Widget>[
      _ProgressHeader(snap: snap, state: state, theme: Theme.of(context), notifier: notifier),
      const SizedBox(height: 12),
      _FormWindowBanner(snap: snap, state: state),
      _BibleSection(snap: snap, notifier: notifier, isToday: state.isToday, pembacaanItems: pembacaanItems),
      ...otherKategoriEntries.map((entry) => _LifeSection(
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
          Expanded(child: Text('Form jurnal hanya bisa diisi pukul ${snap.config.formOpenTime.length >= 5 ? snap.config.formOpenTime.substring(0, 5) : snap.config.formOpenTime.isEmpty ? "-" : snap.config.formOpenTime}–${snap.config.formCloseTime.length >= 5 ? snap.config.formCloseTime.substring(0, 5) : snap.config.formCloseTime.isEmpty ? "-" : snap.config.formCloseTime}.',
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
  final bool isToday;
  final List<CollegeLifeItem> pembacaanItems;

  const _BibleSection({
    required this.snap, 
    required this.notifier, 
    required this.isToday,
    required this.pembacaanItems,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !snap.config.formActive && isToday;

    // Build the side-by-side Bible checkboxes matching the web PDF
    final bibleRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderStrong),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppChecklistTile(
              label: 'Perjanjian Lama',
              sublabel: snap.bible.plText?.isNotEmpty == true ? snap.bible.plText : null,
              checked: snap.bible.plChecked,
              enabled: !disabled,
              onChanged: (v) => notifier.checkBible('pl', v),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderStrong),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppChecklistTile(
              label: 'Perjanjian Baru',
              sublabel: snap.bible.pbText?.isNotEmpty == true ? snap.bible.pbText : null,
              checked: snap.bible.pbChecked,
              enabled: !disabled,
              onChanged: (v) => notifier.checkBible('pb', v),
            ),
          ),
        ],
      ),
    );

    final List<Widget> rows = [
      bibleRow,
    ];

    for (final item in pembacaanItems) {
      rows.add(_LifeSection.buildItemStatic(context, item, snap, notifier, disabled));
    }

    final subtitle = 'Hari ke-${snap.bible.dayNo} — ${snap.bible.plText ?? ''} / ${snap.bible.pbText ?? ''}'.trim();
    
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pembacaan Alkitab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                        if (subtitle.isNotEmpty && subtitle != '— /') ...[
                          const SizedBox(height: 2),
                          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              rows[i],
            ],
          ],
        ),
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
    final numberStr = _sectionNumber(kategori);
    final disabled = !snap.config.formActive && isToday;

    final rows = <Widget>[
      for (final item in items) _buildItem(context, item, snap, notifier, disabled),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppSectionCard(
        headerLeading: Text(numberStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textMuted)),
        title: title,
        rows: rows,
      ),
    );
  }

  Widget _buildItem(BuildContext context, CollegeLifeItem item, CollegeJournalSnapshot snap, CollegeJournalNotifier notifier, bool disabled) {
    return buildItemStatic(context, item, snap, notifier, disabled);
  }

  static Widget buildItemStatic(BuildContext context, CollegeLifeItem item, CollegeJournalSnapshot snap, CollegeJournalNotifier notifier, bool disabled) {
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
        return AppBooleanTile(
          label: item.label,
          value: item.checked,
          enabled: !disabled,
          onChanged: (v) => notifier.toggleBoolean(item.id, v),
        );
      case CollegeItemResponseType.timeRange:
        return _TimeRangeItem(
          item: item,
          snap: snap,
          isEnabled: !disabled,
          notifier: notifier,
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

  static String _sectionNumber(String k) => switch (k) {
        'sidang' => '2',
        'rohani' => '3',
        _ => '',
      };

  static String _sectionTitle(String k) => switch (k) {
        'pembacaan' => 'Item Pembacaan',
        'sidang' => 'Sidang-Sidang Gereja\nOpsional — bisa pilih lebih dari satu',
        'rohani' => 'Rohani & Pelayanan',
        _ => k.toUpperCase(),
      };
}

class _TimeRangeItem extends StatelessWidget {
  final CollegeLifeItem item;
  final CollegeJournalSnapshot snap;
  final bool isEnabled;
  final CollegeJournalNotifier notifier;

  const _TimeRangeItem({
    required this.item,
    required this.snap,
    required this.isEnabled,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final studyLog = snap.studyLogs[item.id];
    final jamMulai = studyLog?.jamMulai ?? '';
    final jamSelesai = studyLog?.jamSelesai ?? '';
    final tipe = studyLog?.tipe ?? 'mandiri';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Di luar jam kuliah \u2014 mandiri atau kelompok',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  context,
                  label: 'Mulai',
                  value: jamMulai,
                  onPicked: (v) => notifier.saveStudyLog(item.id, v, jamSelesai, tipe),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  context,
                  label: 'Selesai',
                  value: jamSelesai,
                  onPicked: (v) => notifier.saveStudyLog(item.id, jamMulai, v, tipe),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented control for Mandiri / Kelompok
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    label: 'Mandiri',
                    isSelected: tipe == 'mandiri',
                    onTap: () => notifier.saveStudyLog(item.id, jamMulai, jamSelesai, 'mandiri'),
                  ),
                ),
                Expanded(
                  child: _buildSegmentButton(
                    label: 'Kelompok',
                    isSelected: tipe == 'kelompok',
                    onTap: () => notifier.saveStudyLog(item.id, jamMulai, jamSelesai, 'kelompok'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(BuildContext context, {required String label, required String value, required ValueChanged<String> onPicked}) {
    return InkWell(
      onTap: isEnabled
          ? () async {
              final initialTime = _parseTime(value);
              final picked = await showTimePicker(context: context, initialTime: initialTime ?? TimeOfDay.now());
              if (picked != null) {
                onPicked('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderStrong),
          borderRadius: BorderRadius.circular(8),
          color: isEnabled ? null : AppColors.background,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              value.isNotEmpty ? value : '--:--',
              style: TextStyle(
                fontSize: 14,
                color: value.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  TimeOfDay? _parseTime(String time) {
    if (time.isEmpty || !time.contains(':')) return null;
    final parts = time.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    return null;
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
        headerLeading: const Text('4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textMuted)),
        title: 'Foto Saat Belajar\n(opsional)',
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
