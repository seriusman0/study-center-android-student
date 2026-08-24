import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../models/mentor_presensi_admin_model.dart';
import '../providers/mentor_presensi_admin_provider.dart';

/// Admin: laporan presensi mentor (cross-branch). List sesi + laporan
/// ringkasan, export CSV/PDF.
class MentorPresensiAdminScreen extends ConsumerStatefulWidget {
  const MentorPresensiAdminScreen({super.key});

  @override
  ConsumerState<MentorPresensiAdminScreen> createState() => _MentorPresensiAdminScreenState();
}

class _MentorPresensiAdminScreenState extends ConsumerState<MentorPresensiAdminScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = now.subtract(const Duration(days: 30));
    _toDate = now;
    Future.microtask(() => _applyFilter());
  }

  void _applyFilter() {
    final from = _fromDate != null ? _fmtDate(_fromDate!) : null;
    final to = _toDate != null ? _fmtDate(_toDate!) : null;
    ref.read(mentorPresensiAdminProvider.notifier).load(from: from, to: to);
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDisplay(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final init = isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now());
    final picked = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(2024), lastDate: DateTime.now());
    if (picked != null) {
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
      _applyFilter();
    }
  }

  Future<void> _export(String type) async {
    final from = _fromDate != null ? _fmtDate(_fromDate!) : null;
    final to = _toDate != null ? _fmtDate(_toDate!) : null;
    final notifier = ref.read(mentorPresensiAdminProvider.notifier);
    String? path;
    if (type == 'csv') {
      path = await notifier.exportExcel(from: from, to: to);
    } else {
      path = await notifier.exportPdf(from: from, to: to);
    }
    if (path != null && mounted) {
      await OpenFilex.open(path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export berhasil')));
    } else if (path == null && mounted) {
      final err = ref.read(mentorPresensiAdminProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Export gagal')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentorPresensiAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Presensi Mentor'),
        actions: [
          if (state.exporting) const Center(child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
          if (!state.exporting) ...[
            IconButton(icon: const Icon(Icons.file_download), tooltip: 'Export CSV', onPressed: () => _export('csv')),
            IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Export PDF', onPressed: () => _export('pdf')),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F766E).withValues(alpha: 0.05),
            child: Column(children: [
              Text('Periode: ${_fromDate != null ? _fmtDisplay(_fromDate!) : '-'} s/d ${_toDate != null ? _fmtDisplay(_toDate!) : '-'}',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              if (state.report != null) ...[
                const Text('Ringkasan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _MiniStat(label: 'Sesi', value: '${state.report!.totals.sesi}')),
                  Expanded(child: _MiniStat(label: 'Jam', value: '${state.report!.totals.jam.toStringAsFixed(1)}')),
                  Expanded(child: _MiniStat(label: 'Murid', value: '${state.report!.totals.murid}')),
                  Expanded(child: _MiniStat(label: 'Mentor Aktif', value: '${state.report!.totals.mentorAktif}')),
                ]),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Expanded(child: _DateChip(label: 'Dari', value: _fromDate, onTap: () => _pickDate(isFrom: true))),
              const SizedBox(width: 8),
              Expanded(child: _DateChip(label: 'Sampai', value: _toDate, onTap: () => _pickDate(isFrom: false))),
            ]),
          ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Gagal: ${state.error}', style: TextStyle(color: Colors.red[400])))
                    : state.entries.isEmpty
                        ? const Center(child: Text('Tidak ada data presensi', style: TextStyle(color: Colors.grey)))
                        : RefreshIndicator(
                            onRefresh: () => ref.read(mentorPresensiAdminProvider.notifier).load(),
                            child: ListView.separated(
                              itemCount: state.entries.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final e = state.entries[i];
                                return ListTile(
                                  leading: const CircleAvatar(backgroundColor: Color(0xFF0F766E), child: Icon(Icons.person, color: Colors.white)),
                                  title: Text(e.mentorName ?? 'Mentor ${e.mentorId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${e.kelasNama ?? '-'} • ${e.tanggal != null ? _fmtDisplay(e.tanggal!) : '-'} • ${e.jumlahMurid} murid${e.cabangNama != null ? '\n${e.cabangNama}' : ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  trailing: e.jamPulang != null ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.access_time, color: Colors.orange),
                                );
                              }),
                          ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
  ]);
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateChip({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final text = value != null ? '${value!.day} ${months[value!.month - 1]} ${value!.year}' : '-';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: const Icon(Icons.calendar_today, size: 16),
        title: Text(label, style: const TextStyle(fontSize: 11)),
        subtitle: Text(text, style: const TextStyle(fontSize: 13)),
        minVerticalPadding: 6,
      ),
    );
  }
}
