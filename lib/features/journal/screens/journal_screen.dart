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
import '../../../shared/widgets/journal_ui_components.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

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
    _previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      _previousHandler?.call(details);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _error = details);
      });
    };
  }

  @override
  void dispose() {
    if (_previousHandler != null) FlutterError.onError = _previousHandler;
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [Icon(Icons.error_outline, color: Colors.red, size: 28), SizedBox(width: 8), Text('Jurnal Error', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))]),
              const SizedBox(height: 8),
              Text(e.exceptionAsString(), style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: () => setState(() => _error = null), icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
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
      if (!jState.loading && jState.snapshot == null) ref.read(journalProvider.notifier).load();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jurnal Harian'),
        actions: [
          IconButton(icon: const Icon(Icons.history), tooltip: 'Riwayat', onPressed: () => context.push('/journal/history')),
          if (state.loading) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
          else IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(journalProvider.notifier).load()),
        ],
      ),
      body: _JournalErrorBoundary(child: _buildBody(context, state, theme)),
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
              Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: () => ref.read(journalProvider.notifier).load(), icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
            ]),
          ),
        );
      }
      if (state.loading) return const Center(child: CircularProgressIndicator());
      return const Center(child: Text('Belum ada data. Tap refresh.'));
    }

    final snap = state.snapshot!;
    final notifier = ref.read(journalProvider.notifier);

    final items = <Widget>[
      JournalHeader(
        userName: ref.watch(authProvider).user?.name ?? 'Student',
        dateString: _formatDate(snap.date),
        isToday: state.isToday,
        onPrev: () => notifier.goToPrevDay(),
        onNext: state.isToday ? null : () => notifier.goToNextDay(),
      ),
      ..._buildSections(snap, notifier, state.isToday),
      _PhotoCard(snap: snap, notifier: notifier),
      JournalSubmitSection(onSubmit: () {}),
    ];

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        cacheExtent: 300,
        itemBuilder: (context, index) => items[index],
      ),
    );
  }

  List<Widget> _buildSections(JournalSnapshot snap, JournalNotifier notifier, bool isToday) {
    final List<Widget> sections = [];
    int sectionIndex = 1;

    // Allah
    final allahItems = snap.lifeItemsByKategori['allah'] ?? [];
    sections.add(
      JournalSectionCard(
        number: sectionIndex.toString(),
        title: 'Allah',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PEMBACAAN ALKITAB', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            if (snap.bible.dayNo != null)
              Text('Hari ke-${snap.bible.dayNo}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: JournalItemBox(child: AppChecklistTile(label: 'Perjanjian Lama', sublabel: snap.bible.plText?.isNotEmpty == true ? snap.bible.plText : (snap.bible.plPorsi.isNotEmpty ? snap.bible.plPorsi : null), checked: snap.bible.plChecked, onChanged: (v) => notifier.checkBible('pl', v)))),
                const SizedBox(width: 8),
                Expanded(child: JournalItemBox(child: AppChecklistTile(label: 'Perjanjian Baru', sublabel: snap.bible.pbText?.isNotEmpty == true ? snap.bible.pbText : (snap.bible.pbPorsi.isNotEmpty ? snap.bible.pbPorsi : null), checked: snap.bible.pbChecked, onChanged: (v) => notifier.checkBible('pb', v)))),
              ],
            ),
            const SizedBox(height: 16),
            const Text('HAFALAN AYAT', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            _HafalAyatSection(snap: snap, notifier: notifier),
            const SizedBox(height: 12),
            ...allahItems.map((item) => JournalItemBox(child: AppChecklistTile(label: item.label, checked: item.checked, onChanged: (v) => notifier.checkLife(item.id, v)))),
          ],
        ),
      )
    );
    sectionIndex++;

    // Other categories
    for (final entry in snap.lifeItemsByKategori.entries) {
      if (entry.key == 'allah' || entry.key == 'kerohanian') continue;
      sections.add(
        JournalSectionCard(
          number: sectionIndex.toString(),
          title: _sectionTitle(entry.key),
          child: Column(
            children: entry.value.map((item) => JournalItemBox(child: AppChecklistTile(label: item.label, checked: item.checked, onChanged: (v) => notifier.checkLife(item.id, v)))).toList(),
          ),
        )
      );
      sectionIndex++;
    }

    return sections;
  }

  String _sectionTitle(String k) => switch (k) {
        'pendidikan' => 'Pendidikan',
        'karakter' => 'Karakter',
        _ => k.toUpperCase(),
      };

  String _formatDate(String date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}

class _HafalAyatSection extends StatefulWidget {
  final JournalSnapshot snap;
  final JournalNotifier notifier;
  const _HafalAyatSection({required this.snap, required this.notifier});

  @override
  State<_HafalAyatSection> createState() => _HafalAyatSectionState();
}

const _bibleBooks = ['Kejadian', 'Matius', 'Markus', 'Lukas', 'Yohanes', 'Kisah Para Rasul', 'Roma', '1 Korintus', '2 Korintus', 'Galatia', 'Efesus', 'Filipi', 'Kolose', '1 Tesalonika', '2 Tesalonika', '1 Timotius', '2 Timotius', 'Titus', 'Filemon', 'Ibrani', 'Yakobus', '1 Petrus', '2 Petrus', '1 Yohanes', '2 Yohanes', '3 Yohanes', 'Yudas', 'Wahyu'];

class _HafalAyatSectionState extends State<_HafalAyatSection> {
  String? _selectedKitab;
  late final TextEditingController _pasal;
  late final TextEditingController _ayat;

  @override
  void initState() {
    super.initState();
    final ref = widget.snap.verseRef ?? '';
    final parsed = _parseRef(ref);
    _selectedKitab = parsed.$1.isNotEmpty ? parsed.$1 : null;
    _pasal = TextEditingController(text: parsed.$2);
    _ayat = TextEditingController(text: parsed.$3);
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
    await widget.notifier.saveVerseRef('$k $p:$a');
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.snap.bible.collegePorsiHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hint.isNotEmpty) Text('Dari porsi hari ini: $hint', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kitab', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.borderStrong), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedKitab,
                        hint: const Text('— Pilih kitab —'),
                        items: _bibleBooks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (v) { setState(() => _selectedKitab = v); _save(); },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pasal', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: _pasal,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderStrong)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderStrong)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => _save(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ayat', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: _ayat,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderStrong)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderStrong)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => _save(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        JournalItemBox(
          child: AppChecklistTile(
            label: 'Sudah hafal ayat ini',
            checked: widget.snap.verseChecked,
            onChanged: (v) {
              if (widget.snap.verseRef == null || widget.snap.verseRef!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi teks ayat terlebih dahulu')));
                return;
              }
              widget.notifier.checkVerseChecked(v);
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final JournalSnapshot snap;
  final JournalNotifier notifier;

  const _PhotoCard({required this.snap, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = snap.photoUrl != null && snap.photoUrl!.isNotEmpty;
    
    return JournalSectionCard(
      number: '4', // Or next number
      title: 'Foto Saat Belajar',
      subtitle: '(OPSIONAL)',
      child: Column(
        children: [
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Image.network(snap.photoUrl!, width: double.infinity, height: 180, fit: BoxFit.cover),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                label: const Text('Hapus Foto', style: TextStyle(color: AppColors.danger)),
                onPressed: () => notifier.deletePhoto(),
              ),
            ),
          ] else
            AppUploadBox(onTap: () => _pickImage(context)),
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
      await notifier.uploadPhoto(file);
    }
  }
}
