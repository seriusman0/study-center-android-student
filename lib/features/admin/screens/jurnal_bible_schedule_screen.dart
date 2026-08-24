import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/jurnal_config_model.dart';
import '../providers/jurnal_bible_schedule_provider.dart';

const _bulanLabels = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

class JurnalBibleScheduleScreen extends ConsumerStatefulWidget {
  const JurnalBibleScheduleScreen({super.key});

  @override
  ConsumerState<JurnalBibleScheduleScreen> createState() => _JurnalBibleScheduleScreenState();
}

class _JurnalBibleScheduleScreenState extends ConsumerState<JurnalBibleScheduleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(jurnalBibleScheduleProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jurnalBibleScheduleProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Pembacaan Alkitab')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        onPressed: () => _showForm(context, defaultMonth: state.bulan, defaultYear: state.tahun),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text('${_bulanLabels[state.bulan]} ${state.tahun}'),
                    onPressed: () => _pickMonth(context, state.bulan, state.tahun),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(jurnalBibleScheduleProvider.notifier).load(),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(jurnalBibleScheduleProvider.notifier).load(),
              child: state.loading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.items.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text('Gagal memuat: ${state.error}',
                                  style: TextStyle(color: Colors.red[400])),
                            ),
                          ],
                        )
                      : state.items.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                    child: Text('Belum ada jadwal untuk bulan ini',
                                        style: TextStyle(color: Colors.grey))),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 90),
                              itemCount: state.items.length,
                              itemBuilder: (context, i) {
                                final item = state.items[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                      child: Text('${item.tanggal.day}',
                                          style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    title: Text(
                                      '${item.tanggal.day} ${_bulanLabels[item.tanggal.month]} ${item.tanggal.year}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      'PL: ${item.plPorsi ?? "-"}\nPB: ${item.pbPorsi ?? "-"}',
                                    ),
                                    isThreeLine: true,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => _showActions(context, item),
                                    ),
                                    onTap: () => _showActions(context, item),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context, int currentMonth, int currentYear) async {
    int selMonth = currentMonth;
    int selYear = currentYear;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pilih Bulan & Tahun', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selMonth,
                        decoration: const InputDecoration(labelText: 'Bulan', border: OutlineInputBorder()),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(value: i + 1, child: Text(_bulanLabels[i + 1])),
                        ),
                        onChanged: (v) => setSheetState(() => selMonth = v ?? selMonth),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selYear,
                        decoration: const InputDecoration(labelText: 'Tahun', border: OutlineInputBorder()),
                        items: List.generate(
                          6,
                          (i) {
                            final y = DateTime.now().year - 1 + i;
                            return DropdownMenuItem(value: y, child: Text('$y'));
                          },
                        ),
                        onChanged: (v) => setSheetState(() => selYear = v ?? selYear),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(jurnalBibleScheduleProvider.notifier).load(bulan: selMonth, tahun: selYear);
                  },
                  child: const Text('Tampilkan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, JurnalBibleSchedule item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Jadwal'),
              onTap: () {
                Navigator.pop(ctx);
                _showForm(context, item: item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, JurnalBibleSchedule item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: Text(
            'Jadwal tanggal ${item.tanggal.day} ${_bulanLabels[item.tanggal.month]} ${item.tanggal.year} akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref.read(jurnalBibleScheduleProvider.notifier).delete(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Jadwal dihapus' : 'Gagal menghapus jadwal')),
        );
      }
    }
  }

  Future<void> _showForm(BuildContext context,
      {JurnalBibleSchedule? item, int? defaultMonth, int? defaultYear}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BibleScheduleFormSheet(
        item: item,
        defaultMonth: defaultMonth,
        defaultYear: defaultYear,
      ),
    );
  }
}

class _BibleScheduleFormSheet extends ConsumerStatefulWidget {
  final JurnalBibleSchedule? item;
  final int? defaultMonth;
  final int? defaultYear;

  const _BibleScheduleFormSheet({this.item, this.defaultMonth, this.defaultYear});

  @override
  ConsumerState<_BibleScheduleFormSheet> createState() => _BibleScheduleFormSheetState();
}

class _BibleScheduleFormSheetState extends ConsumerState<_BibleScheduleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _tanggal;
  late final TextEditingController _plCtrl;
  late final TextEditingController _pbCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tanggal = widget.item?.tanggal ??
        DateTime(widget.defaultYear ?? now.year, widget.defaultMonth ?? now.month, now.day);
    _plCtrl = TextEditingController(text: widget.item?.plPorsi ?? '');
    _pbCtrl = TextEditingController(text: widget.item?.pbPorsi ?? '');
  }

  @override
  void dispose() {
    _plCtrl.dispose();
    _pbCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final newItem = JurnalBibleSchedule(
      id: widget.item?.id ?? 0,
      tanggal: _tanggal,
      plPorsi: _plCtrl.text.trim().isEmpty ? null : _plCtrl.text.trim(),
      pbPorsi: _pbCtrl.text.trim().isEmpty ? null : _pbCtrl.text.trim(),
    );

    final notifier = ref.read(jurnalBibleScheduleProvider.notifier);
    final ok = widget.item == null
        ? await notifier.create(newItem)
        : await notifier.update(widget.item!.id, newItem);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan jadwal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Edit Jadwal Alkitab' : 'Tambah Jadwal Alkitab',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                      '${_tanggal.day} ${_bulanLabels[_tanggal.month]} ${_tanggal.year}'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plCtrl,
                decoration: const InputDecoration(
                  labelText: 'Porsi Perjanjian Lama (PL)',
                  hintText: 'mis. Kejadian 1-3',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pbCtrl,
                decoration: const InputDecoration(
                  labelText: 'Porsi Perjanjian Baru (PB)',
                  hintText: 'mis. Matius 1',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
