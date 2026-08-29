import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/college_review_model.dart';
import '../repositories/college_repository.dart';

class CollegeReviewDetailScreen extends ConsumerStatefulWidget {
  final int journalId;
  const CollegeReviewDetailScreen({super.key, required this.journalId});

  @override
  ConsumerState<CollegeReviewDetailScreen> createState() => _CollegeReviewDetailScreenState();
}

class _CollegeReviewDetailScreenState extends ConsumerState<CollegeReviewDetailScreen> {
  ScholarshipJournalDetail? _detail;
  bool _loading = true;
  String? _error;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detail = await ref.read(collegeReviewRepositoryProvider).detail(widget.journalId);
      setState(() {
        _detail = detail;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Jurnal'),
        actions: [
          if (_detail?.canReview == true)
              IconButton(icon: const Icon(Icons.save), onPressed: () => _submitReview('approved')),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Coba lagi'), onPressed: _load),
          ]),
        ),
      );
    }

    final d = _detail;
    if (d == null) return const Center(child: Text('Data tidak tersedia'));

    final item = d.item;
    final s = d.student;
    final period = DateFormat('MMMM yyyy', 'id').format(
      DateTime(d.periodYear, d.periodMonth),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.teal.shade100,
              child: Text(s.name.substring(0, s.name.length >= 2 ? 2 : 1).toUpperCase(),
                  style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (s.campus != null) Text(s.campus!, style: TextStyle(color: Colors.grey[600])),
            if (s.semester != null) Text('Semester ${s.semester}', style: TextStyle(color: Colors.grey[600])),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor(d.status).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(d.statusLabel, style: TextStyle(color: _statusColor(d.status), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 20),
        Text(d.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Periode: $period • Dikirim: ${d.submittedAt ?? "Draft"}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),

        const SizedBox(height: 24),
        // Review form sections
        if (item != null) ...[
          _buildSectionTitle('I. Akademik'),
          if (item.gpaCurrentSemester != null)
            _kv('IPK Semester Ini', item.gpaCurrentSemester!.toStringAsFixed(2)),
          if (item.cumulativeGpa != null)
            _kv('IPK Kumulatif', item.cumulativeGpa!.toStringAsFixed(2)),
          if (item.classAttendancePercentage != null)
            _kv('Kehadiran Kelas', '${item.classAttendancePercentage!.toStringAsFixed(1)}%'),
          if (item.academicSummary != null && item.academicSummary!.isNotEmpty)
            _paragraph('Ringkasan Akademik', item.academicSummary!),
          const SizedBox(height: 16),
          _buildSectionTitle('II. Organisasi & Kegiatan'),
          if (item.organizationActivities != null && item.organizationActivities!.isNotEmpty)
            _paragraph('Aktivitas Organisasi', item.organizationActivities!),
          const SizedBox(height: 16),
          _buildSectionTitle('III. Pelatihan & Seminar'),
          if (item.trainingSeminars != null && item.trainingSeminars!.isNotEmpty)
            _paragraph('Pelatihan/Seminar', item.trainingSeminars!),
          const SizedBox(height: 16),
          _buildSectionTitle('IV. Pencapaian'),
          if (item.achievements != null && item.achievements!.isNotEmpty)
            _paragraph('Pencapaian', item.achievements!),
          const SizedBox(height: 16),
          _buildSectionTitle('V. Pengabdian / Pelayanan'),
          if (item.communityServiceDetails != null && item.communityServiceDetails!.isNotEmpty)
            _paragraph('Detail Pelayanan', item.communityServiceDetails!),
          if (item.serviceHours != null) _kv('Total Jam Pelayanan', item.serviceHours.toString()),
          const SizedBox(height: 16),
          _buildSectionTitle('VI. Refleksi & Tujuan'),
          if (item.personalReflection != null && item.personalReflection!.isNotEmpty)
            _paragraph('Refleksi Pribadi', item.personalReflection!),
          if (item.nextMonthGoals != null && item.nextMonthGoals!.isNotEmpty)
            _paragraph('Tujuan Bulan Depan', item.nextMonthGoals!),
        ],

        const SizedBox(height: 16),
        // Attachments
        if (d.attachments.isNotEmpty) ...[
          _buildSectionTitle('Lampiran'),
          Wrap(spacing: 10, runSpacing: 10, children: d.attachments.map((a) =>
            Chip(label: Text(a.name), avatar: Icon(Icons.attach_file, color: Colors.teal[700] as Color?))).toList()),
        ],

        // Reviewer notes
        if (d.reviewerNotes != null && d.reviewerNotes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Catatan Reviewer'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[50] as Color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300] as Color)),
            child: Text(d.reviewerNotes!),
          ),
        ],

        // Review action
        if (d.canReview) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Aksi Review'),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _submitReview('approved'),
              icon: const Icon(Icons.check),
              label: const Text('Setujui'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _submitReview('revision'),
              icon: const Icon(Icons.edit_note),
              label: const Text('Revisi'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _submitReview('rejected'),
              icon: const Icon(Icons.close),
              label: const Text('Tolak'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            )),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Catatan Reviewer (opsional)', border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ]),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 140, child: Text(k, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500))),
          Expanded(child: Text(v, style: const TextStyle(color: Colors.black87))),
        ]),
      );

  Widget _paragraph(String label, String text) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 2),
        Text(text, style: const TextStyle(color: Colors.black87, height: 1.4)),
      ]);

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.teal, fontWeight: FontWeight.w700)),
      );

  Future<void> _submitReview(String action) async {
    final notes = _notesCtrl.text.trim();
    try {
      await ref.read(collegeReviewRepositoryProvider).submitReview(
            widget.journalId,
            action: action,
            notes: notes.isNotEmpty ? notes : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review $action berhasil disimpan')));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.settings.name == 'collegeReviewList');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': case 'accepted': case 'diterima': return Colors.green;
      case 'rejected': case 'ditolak': return Colors.red;
      case 'revision': case 'revisi': return Colors.orange;
      default: return Colors.blueGrey;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }
}
