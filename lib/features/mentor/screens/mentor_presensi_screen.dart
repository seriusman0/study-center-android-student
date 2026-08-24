import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/kelas_master_model.dart';
import '../models/presensi_model.dart';
import '../providers/kelas_master_provider.dart';
import '../providers/presensi_provider.dart';

class MentorPresensiScreen extends ConsumerStatefulWidget {
  const MentorPresensiScreen({super.key});

  @override
  ConsumerState<MentorPresensiScreen> createState() => _MentorPresensiScreenState();
}

class _MentorPresensiScreenState extends ConsumerState<MentorPresensiScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(presensiProvider.notifier).load();
      // Kelas list is reused by the create-session sheet's dropdown.
      final kState = ref.read(kelasMasterProvider);
      if (kState.items.isEmpty && !kState.loading) {
        ref.read(kelasMasterProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(presensiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Presensi Siswa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSession(context),
        icon: const Icon(Icons.add),
        label: const Text('Presensi Baru'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(presensiProvider.notifier).load(),
        child: state.loading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                          child: Text('Belum ada presensi',
                              style: TextStyle(color: Colors.grey))),
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
                            '${_formatDate(p.tanggal)} • ${p.jamMulai}-${p.jamSelesai}'
                            '${p.studentsCount != null ? ' • ${p.studentsCount} siswa' : ''}',
                          ),
                          isThreeLine: p.materi.isNotEmpty,
                          onTap: () => _showDetail(context, p),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('d MMM yyyy', 'id').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  void _showDetail(BuildContext context, Presensi p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.kelasNama ?? 'Kelas #${p.kelasId}',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${_formatDate(p.tanggal)} • ${p.jamMulai}-${p.jamSelesai}',
                  style: TextStyle(color: Colors.grey[600])),
              if (p.materi.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Materi', style: Theme.of(ctx).textTheme.labelLarge),
                Text(p.materi),
              ],
              const SizedBox(height: 16),
              Text('Kehadiran', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: p.students.length,
                  itemBuilder: (ctx, i) {
                    final s = p.students[i];
                    return ListTile(
                      dense: true,
                      title: Text(s.name),
                      trailing: _StatusChip(status: s.status),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateSession(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _CreatePresensiSheet(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'hadir': Colors.green,
      'izin': Colors.orange,
      'sakit': Colors.blue,
      'alpha': Colors.red,
    };
    final labels = {
      'hadir': 'Hadir',
      'izin': 'Izin',
      'sakit': 'Sakit',
      'alpha': 'Alpha',
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(labels[status] ?? status,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// New attendance session: pick kelas, date/time, materi, then search &
/// select students with a per-student status (defaults hadir).
class _CreatePresensiSheet extends ConsumerStatefulWidget {
  const _CreatePresensiSheet();

  @override
  ConsumerState<_CreatePresensiSheet> createState() => _CreatePresensiSheetState();
}

class _CreatePresensiSheetState extends ConsumerState<_CreatePresensiSheet> {
  KelasMaster? _selectedKelas;
  DateTime _tanggal = DateTime.now();
  TimeOfDay _jamMulai = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamSelesai = const TimeOfDay(hour: 10, minute: 0);
  final _materiCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final Map<int, StudentSearchResult> _selected = {};
  final Map<int, String> _statusByStudent = {};
  bool _saving = false;

  @override
  void dispose() {
    _materiCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final kelasList = ref.watch(kelasMasterProvider).items;
    final searchResults = ref.watch(studentSearchProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Presensi Baru', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  DropdownButtonFormField<KelasMaster>(
                    initialValue: _selectedKelas,
                    decoration: const InputDecoration(labelText: 'Kelas'),
                    items: kelasList
                        .map((k) => DropdownMenuItem(value: k, child: Text(k.nama)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedKelas = v),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal'),
                    subtitle: Text(DateFormat('d MMM yyyy', 'id').format(_tanggal)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _tanggal,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _tanggal = picked);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Mulai'),
                          subtitle: Text(_fmtTime(_jamMulai)),
                          onTap: () async {
                            final picked =
                                await showTimePicker(context: context, initialTime: _jamMulai);
                            if (picked != null) setState(() => _jamMulai = picked);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Selesai'),
                          subtitle: Text(_fmtTime(_jamSelesai)),
                          onTap: () async {
                            final picked =
                                await showTimePicker(context: context, initialTime: _jamSelesai);
                            if (picked != null) setState(() => _jamSelesai = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _materiCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Materi'),
                  ),
                  const SizedBox(height: 16),
                  Text('Siswa (${_selected.length} dipilih)',
                      style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cari nama siswa',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => ref.read(studentSearchProvider.notifier).search(v),
                  ),
                  const SizedBox(height: 8),
                  ...searchResults.where((s) => !_selected.containsKey(s.id)).map(
                        (s) => ListTile(
                          dense: true,
                          title: Text(s.name),
                          subtitle: s.kelas != null ? Text(s.kelas!) : null,
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => setState(() {
                            _selected[s.id] = s;
                            _statusByStudent[s.id] = 'hadir';
                          }),
                        ),
                      ),
                  if (_selected.isNotEmpty) ...[
                    const Divider(),
                    ..._selected.values.map((s) => ListTile(
                          dense: true,
                          title: Text(s.name),
                          trailing: SizedBox(
                            width: 140,
                            child: DropdownButtonFormField<String>(
                              initialValue: _statusByStudent[s.id] ?? 'hadir',
                              isDense: true,
                              items: const [
                                DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                                DropdownMenuItem(value: 'izin', child: Text('Izin')),
                                DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                                DropdownMenuItem(value: 'alpha', child: Text('Alpha')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _statusByStudent[s.id] = v ?? 'hadir'),
                            ),
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => setState(() {
                              _selected.remove(s.id);
                              _statusByStudent.remove(s.id);
                            }),
                          ),
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan Presensi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final user = ref.read(authProvider).user;
    if (user == null || _selectedKelas == null || _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kelas dan minimal 1 siswa')),
      );
      return;
    }
    if (_materiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Materi wajib diisi')));
      return;
    }

    setState(() => _saving = true);
    final ok = await ref.read(presensiProvider.notifier).create(
          mentorId: user.id,
          kelasId: _selectedKelas!.id,
          tanggal: DateFormat('yyyy-MM-dd').format(_tanggal),
          jamMulai: _fmtTime(_jamMulai),
          jamSelesai: _fmtTime(_jamSelesai),
          materi: _materiCtrl.text.trim(),
          studentIds: _selected.keys.toList(),
          studentStatus: _statusByStudent,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal menyimpan presensi')));
    }
  }
}
