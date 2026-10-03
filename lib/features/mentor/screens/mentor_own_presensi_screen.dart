import '../models/mentor_presensi_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/kelas_master_model.dart';
import '../providers/kelas_master_provider.dart';
import '../providers/mentor_presensi_provider.dart';
import '../../../shared/theme/design_tokens.dart';

class MentorOwnPresensiScreen extends ConsumerStatefulWidget {
  const MentorOwnPresensiScreen({super.key});

  @override
  ConsumerState<MentorOwnPresensiScreen> createState() => _MentorOwnPresensiScreenState();
}

class _MentorOwnPresensiScreenState extends ConsumerState<MentorOwnPresensiScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mentorPresensiProvider.notifier).load();
      final kState = ref.read(kelasMasterProvider);
      if (kState.items.isEmpty && !kState.loading) {
        ref.read(kelasMasterProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentorPresensiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Kehadiran Anda')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Isi Kehadiran'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(mentorPresensiProvider.notifier).load(),
        child: state.loading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                          child: Text('Belum ada log kehadiran',
                              style: TextStyle(color: AppColors.textMuted))),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (ctx, i) {
                      final p = state.items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(p.kelasNama ?? 'Kelas #${p.kelasId}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '\${_formatDate(p.tanggal)} • \${p.jamDatang}-\${p.jamPulang}\n\${p.jumlahMurid} murid • \${p.catatan ?? \"-\"}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _openCreateForm(context, p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(p.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Log?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final success = await ref.read(mentorPresensiProvider.notifier).destroy(id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.read(mentorPresensiProvider).error ?? 'Gagal menghapus')));
      }
    }
  }

  void _openCreateForm(BuildContext context, [MentorPresensi? initial]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CreateForm(initial: initial),
      ),
    );
  }
}


class _CreateForm extends ConsumerStatefulWidget {
  final MentorPresensi? initial;
  const _CreateForm({this.initial});
  @override
  ConsumerState<_CreateForm> createState() => _CreateFormState();
}


class _CreateFormState extends ConsumerState<_CreateForm> {
  KelasMaster? _selectedKelas;
  DateTime _tanggal = DateTime.now();
  TimeOfDay _jamDatang = TimeOfDay.now();
  TimeOfDay _jamPulang = TimeOfDay.now();
  final _muridCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  bool _saving = false;


  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final kState = ref.read(kelasMasterProvider);
      try {
        _selectedKelas = kState.items.firstWhere((k) => k.id == widget.initial!.kelasId);
      } catch (_) {}
      
      try {
        _tanggal = DateTime.parse(widget.initial!.tanggal);
      } catch (_) {}
      
      try {
        final p = widget.initial!.jamDatang.split(':');
        _jamDatang = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      } catch (_) {}
      
      try {
        final p = widget.initial!.jamPulang.split(':');
        _jamPulang = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      } catch (_) {}
      
      _muridCtrl.text = widget.initial!.jumlahMurid.toString();
      _catatanCtrl.text = widget.initial!.catatan ?? '';
    }
  }

  @override
  void dispose() {

    _muridCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_selectedKelas == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kelas!')));
      return;
    }
    final murid = int.tryParse(_muridCtrl.text) ?? -1;
    if (murid < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah murid tidak valid!')));
      return;
    }

    setState(() => _saving = true);
    final ok = await ref.read(mentorPresensiProvider.notifier).create(
      kelasId: _selectedKelas!.id,
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggal),
      jamDatang: _fmtTime(_jamDatang),
      jamPulang: _fmtTime(_jamPulang),
      jumlahMurid: murid,
      catatan: _catatanCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      final err = ref.read(mentorPresensiProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Gagal')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kelasState = ref.watch(kelasMasterProvider);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Isi Kehadiran Mentor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<KelasMaster>(
            decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
            value: _selectedKelas,
            items: kelasState.items.map((k) {
              return DropdownMenuItem(value: k, child: Text(k.nama));
            }).toList(),
            onChanged: (v) => setState(() => _selectedKelas = v),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Tanggal'),
            subtitle: Text(DateFormat('dd MMM yyyy').format(_tanggal)),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _tanggal,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _tanggal = d);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Jam Datang'),
                  subtitle: Text(_jamDatang.format(context)),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _jamDatang);
                    if (t != null) setState(() => _jamDatang = t);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListTile(
                  title: const Text('Jam Pulang'),
                  subtitle: Text(_jamPulang.format(context)),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _jamPulang);
                    if (t != null) setState(() => _jamPulang = t);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _muridCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Jumlah Murid Hadir', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _catatanCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Catatan/Materi (Opsional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}


