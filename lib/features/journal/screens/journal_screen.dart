import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../models/journal_model.dart';
import '../providers/journal_provider.dart';

const _kitabList = [
  'Kejadian','Keluaran','Imamat','Bilangan','Ulangan','Yosua','Hakim-hakim','Rut',
  '1 Samuel','2 Samuel','1 Raja-raja','2 Raja-raja','1 Tawarikh','2 Tawarikh',
  'Ezra','Nehemia','Ester','Ayub','Mazmur','Amsal','Pengkhotbah','Kidung Agung',
  'Yesaya','Yeremia','Ratapan','Yehezkiel','Daniel','Hosea','Yoel','Amos',
  'Obaja','Yunus','Mikha','Nahum','Habakuk','Zefanya','Hagai','Zakharia','Maleakhi',
  'Matius','Markus','Lukas','Yohanes','Kisah Para Rasul','Roma',
  '1 Korintus','2 Korintus','Galatia','Efesus','Filipi','Kolose',
  '1 Tesalonika','2 Tesalonika','1 Timotius','2 Timotius','Titus','Filemon',
  'Ibrani','Yakobus','1 Petrus','2 Petrus','1 Yohanes','2 Yohanes','3 Yohanes',
  'Yudas','Wahyu',
];

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _frameReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _frameReady = true);
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
        title: const Text('Jurnal'),
        actions: [
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(journalProvider.notifier).load(),
            ),
        ],
      ),
      body: _buildBody(context, state, theme),
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
              ElevatedButton.icon(
                onPressed: () => ref.read(journalProvider.notifier).load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ]),
          ),
        );
      }
      if (!state.loading) {
        return const Center(child: Text('Gagal memuat. Tap refresh.', style: TextStyle(color: Colors.grey)));
      }
      return const Center(child: CircularProgressIndicator());
    }

    final snap = state.snapshot!;
    final notifier = ref.read(journalProvider.notifier);
    final streak = ref.watch(homeProvider).laporan?.streak;

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ProgressHeader(checked: snap.checkedCount, total: snap.totalCount, date: snap.date, streak: streak),
          const SizedBox(height: 16),
          _SectionCard(
            number: '1',
            title: 'Pembacaan Alkitab',
            children: [
              _CheckRow(
                label: 'Perjanjian Lama',
                checked: snap.bible.plChecked,
                onTap: () => notifier.checkBible('pl', !snap.bible.plChecked),
              ),
              _CheckRow(
                label: 'Perjanjian Baru',
                checked: snap.bible.pbChecked,
                onTap: () => notifier.checkBible('pb', !snap.bible.pbChecked),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _VerseSection(verseRef: snap.verseRef),
          const SizedBox(height: 12),
          _LifeScheduleCard(snap: snap, notifier: notifier),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int checked;
  final int total;
  final String date;
  final int? streak;

  const _ProgressHeader({required this.checked, required this.total, required this.date, this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? checked / total : 0.0;
    final formatted = _formatDate(date);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                'Jurnal $formatted',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$checked/$total',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          if (streak != null && streak! > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  'Streak $streak hari berturut-turut',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ]),
      ),
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
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            ),
            const SizedBox(width: 8),
            Text('Jadwal Kehidupan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          for (final entry in byKategori.entries) ...[
            const SizedBox(height: 8),
            Text(
              _kategoriLabel(entry.key),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
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
      case 'kerohanian': return 'KEROHANIAN';
      case 'pendidikan': return 'PENDIDIKAN';
      case 'karakter': return 'KARAKTER';
      default: return k.toUpperCase();
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String number;
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.number, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool checked;
  final VoidCallback onTap;

  const _CheckRow({required this.label, this.subtitle, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Checkbox(
            value: checked,
            onChanged: (_) => onTap(),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                label,
                style: TextStyle(
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? Colors.grey : null,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _VerseInputCard extends StatefulWidget {
  final String? initialRef;
  final Future<void> Function(String?) onSave;

  const _VerseInputCard({this.initialRef, required this.onSave});

  @override
  State<_VerseInputCard> createState() => _VerseInputCardState();
}

class _VerseInputCardState extends State<_VerseInputCard> {
  late final TextEditingController _kitab;
  late final TextEditingController _pasal;
  late final TextEditingController _ayat;
  String _savedLabel = '';

  @override
  void initState() {
    super.initState();
    final ref = widget.initialRef ?? '';
    final parsed = _parseRef(ref);
    _kitab = TextEditingController(text: parsed.$1);
    _pasal = TextEditingController(text: parsed.$2);
    _ayat  = TextEditingController(text: parsed.$3);
    _savedLabel = ref;
  }

  @override
  void didUpdateWidget(_VerseInputCard old) {
    super.didUpdateWidget(old);
    final newRef = widget.initialRef ?? '';
    if (newRef != _savedLabel && newRef.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _kitab.clear(); _pasal.clear(); _ayat.clear();
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
    final k = _kitab.text.trim();
    final p = _pasal.text.trim();
    final a = _ayat.text.trim();
    if (k.isEmpty || p.isEmpty || a.isEmpty) return;
    final ref = '$k $p:$a';
    if (ref == _savedLabel) return;
    _savedLabel = ref;
    await widget.onSave(ref);
    if (mounted) setState(() {});
  }

  Future<void> _clear() async {
    _kitab.clear(); _pasal.clear(); _ayat.clear();
    _savedLabel = '';
    await widget.onSave(null);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _kitab.dispose(); _pasal.dispose(); _ayat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final hasInput = _kitab.text.isNotEmpty || _pasal.text.isNotEmpty || _ayat.text.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            ),
            const SizedBox(width: 8),
            Text('Hafal Ayat Mingguan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Pilih satu ayat dari porsi bacaan hari ini.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kitab,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDeco('Kitab (cth. Yohanes)'),
            onEditingComplete: _save,
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _pasal,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDeco('Pasal'),
                onEditingComplete: _save,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ayat,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDeco('Ayat'),
                onEditingComplete: _save,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (_savedLabel.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text('Tersimpan: $_savedLabel',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.green[700], fontWeight: FontWeight.w500)),
              ])
            else
              const SizedBox.shrink(),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (hasInput)
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (!hasInput || _savedLabel.isEmpty)
                ElevatedButton(
                  onPressed: hasInput ? _save : null,
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Simpan'),
                ),
            ]),
          ]),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      );
}

class _VerseSection extends StatelessWidget {
  final String? verseRef;
  const _VerseSection({this.verseRef});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            ),
            const SizedBox(width: 8),
            Text('Hafal Ayat Mingguan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (verseRef != null && verseRef!.isNotEmpty)
            Row(children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(verseRef!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ])
          else
            Text('Belum ada ayat hafalan hari ini.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
        ]),
      ),
    );
  }
}
