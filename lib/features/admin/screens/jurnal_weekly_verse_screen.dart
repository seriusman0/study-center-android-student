import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/jurnal_config_model.dart';
import '../providers/jurnal_weekly_verse_provider.dart';

/// Admin screen: ayat hafalan mingguan (Weekly Verse). Filter tahun via
/// ListWheelPicker, tambah/edit via dialog, hapus via konfirmasi.
class JurnalWeeklyVerseScreen extends ConsumerStatefulWidget {
  const JurnalWeeklyVerseScreen({super.key});

  @override
  ConsumerState<JurnalWeeklyVerseScreen> createState() => _JurnalWeeklyVerseScreenState();
}

class _JurnalWeeklyVerseScreenState extends ConsumerState<JurnalWeeklyVerseScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(jurnalWeeklyVerseProvider.notifier).load());
  }

  void _showForm(BuildContext ctx, {JurnalWeeklyVerse? existing}) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => _WeeklyVerseForm(existing: existing),
    );
  }

  void _confirmDelete(BuildContext ctx, JurnalWeeklyVerse item) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Ayat?'),
        content: Text('Referensi "${item.referensi}" (Minggu ${item.minggu}) akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(jurnalWeeklyVerseProvider.notifier).delete(item.id);
              Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jurnalWeeklyVerseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ayat Hafalan (${state.tahun})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pilih tahun',
            onPressed: () async {
              final picked = await showDialog<int>(context: context, builder: (ctx) => const _YearPicker());
              if (picked != null) ref.read(jurnalWeeklyVerseProvider.notifier).load(tahun: picked);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Gagal: ${state.error}', style: TextStyle(color: Colors.red[400])))
              : state.items.isEmpty
                  ? const Center(child: Text('Belum ada ayat hafalan untuk tahun ini', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = state.items[i];
                        return ListTile(
                          leading: const Icon(Icons.book, color: Color(0xFF0F766E)),
                          title: Text('${item.referensi} — MINGGU ${item.minggu}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Bulan ${item.bulan}/${item.tahun}', style: const TextStyle(fontSize: 11)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => _confirmDelete(context, item),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _WeeklyVerseForm extends ConsumerWidget {
  final JurnalWeeklyVerse? existing;
  const _WeeklyVerseForm({this.existing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = existing != null;
    final refCtrl = TextEditingController(text: existing?.referensi ?? '');
    final isiCtrl = TextEditingController(text: existing?.isi ?? '');
    final tahunCtrl = TextEditingController(text: ref.read(jurnalWeeklyVerseProvider).tahun.toString());
    final bulanCtrl = TextEditingController(text: existing != null ? '${existing!.bulan}' : '1');
    final mingguCtrl = TextEditingController(text: existing != null ? '${existing!.minggu}' : '1');

    return AlertDialog(
      title: Text(isEdit ? 'Edit Ayat' : 'Tambah Ayat'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Referensi (e.g. Kis 1:9)', isDense: true), maxLines: 1),
            const SizedBox(height: 10),
            TextField(controller: isiCtrl, decoration: const InputDecoration(labelText: 'Isi Ayat'), maxLines: 3),
            const SizedBox(height: 10),
            TextField(controller: tahunCtrl, decoration: const InputDecoration(labelText: 'Tahun', isDense: true), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: bulanCtrl, decoration: const InputDecoration(labelText: 'Bulan (1-12)', isDense: true), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: mingguCtrl, decoration: const InputDecoration(labelText: 'Minggu (1-53)', isDense: true), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final item = JurnalWeeklyVerse(
              id: existing?.id ?? 0,
              tahun: int.tryParse(tahunCtrl.text) ?? DateTime.now().year,
              bulan: int.tryParse(bulanCtrl.text) ?? 1,
              minggu: int.tryParse(mingguCtrl.text) ?? 1,
              referensi: refCtrl.text,
              isi: isiCtrl.text,
            );
            if (isEdit) {
              ref.read(jurnalWeeklyVerseProvider.notifier).update(existing!.id, item);
            } else {
              ref.read(jurnalWeeklyVerseProvider.notifier).create(item);
            }
            Navigator.pop(context);
          },
          child: Text(isEdit ? 'Update' : 'Tambah'),
        ),
      ],
    );
  }
}

class _YearPicker extends ConsumerWidget {
  const _YearPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final currentYear = ref.watch(jurnalWeeklyVerseProvider).tahun;
    return AlertDialog(
      title: const Text('Pilih Tahun'),
      content: SizedBox(
        width: 220,
        height: 180,
        child: ListWheelScrollView(
          itemExtent: 40,
          onSelectedItemChanged: (i) {
            final year = now.year - i + 5;
            if (year != currentYear) ref.read(jurnalWeeklyVerseProvider.notifier).load(tahun: year);
          },
          children: List.generate(21, (i) {
            final year = now.year - i + 5;
            return Center(
              child: Text('$year', style: TextStyle(
                fontWeight: year == currentYear ? FontWeight.w700 : FontWeight.normal,
                color: year == currentYear ? Theme.of(context).colorScheme.primary : null,
              )),
            );
          }),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, currentYear), child: const Text('OK'))],
    );
  }
}
