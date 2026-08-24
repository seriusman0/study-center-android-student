import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/certificate_model.dart';
import '../providers/certificates_provider.dart';

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Admin: kelola template sertifikat + lihat/download sertifikat yang diterbitkan.
class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(certTemplatesProvider.notifier).load();
      ref.read(issuedCertificatesProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sertifikat'),
        bottom: const TabBar(tabs: [Tab(text: 'Template'), Tab(text: 'Diterbitkan')]),
      ),
      floatingActionButton: Builder(builder: (ctx) {
        final isTemplates = _tabController.index == 0;
        return FloatingActionButton(
          onPressed: () => isTemplates ? _showTemplateForm(ctx) : _showIssueForm(ctx),
          child: Icon(isTemplates ? Icons.add : Icons.campaign),
        );
      }),
      body: TabBarView(
        controller: _tabController,
        children: const [_TemplatesTab(), _IssuedTab()],
      ),
    );
  }

  void _showTemplateForm(BuildContext ctx) {
    showDialog(context: ctx, builder: (d) => const _TemplateForm(isEdit: false));
  }

  void _showIssueForm(BuildContext ctx) {
    showDialog(context: ctx, builder: (d) => const _IssueForm());
  }
}

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  void _edit(BuildContext ctx, CertificateTemplate t) {
    showDialog(context: ctx, builder: (d) => _TemplateForm(isEdit: true, existing: t));
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref, CertificateTemplate t) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Hapus Template?'),
        content: Text('Template "${t.nama}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(certTemplatesProvider.notifier).delete(t.id);
              Navigator.pop(d);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(certTemplatesProvider);
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) return Center(child: Text('Gagal: ${state.error}', style: TextStyle(color: Colors.red[400])));
    if (state.templates.isEmpty) return const Center(child: Text('Belum ada template', style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      itemCount: state.templates.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = state.templates[i];
        return ListTile(
          leading: const Icon(Icons.description, color: Color(0xFF0F766E)),
          title: Text(t.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${t.orientation} • ${t.paperSize} • ${t.isActive ? "Aktif" : "Nonaktif"}', style: const TextStyle(fontSize: 11)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (v) {
              if (v == 'edit') _edit(context, t);
              if (v == 'delete') _confirmDelete(context, ref, t);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        );
      },
    );
  }
}

class _TemplateForm extends ConsumerStatefulWidget {
  final bool isEdit;
  final CertificateTemplate? existing;

  const _TemplateForm({this.isEdit = false, this.existing});

  @override
  ConsumerState<_TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends ConsumerState<_TemplateForm> {
  late final _namaCtrl, _deskripsiCtrl, _htmlCtrl;
  String _orientation = 'portrait';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.existing?.nama ?? '');
    _deskripsiCtrl = TextEditingController(text: widget.existing?.deskripsi ?? '');
    _htmlCtrl = TextEditingController(text: widget.existing?.htmlContent ?? '');
    _orientation = widget.existing?.orientation ?? 'portrait';
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Template' : 'Template Baru'),
      content: SizedBox(
        width: 500, height: 380,
        child: Column(
          children: [
            TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama', isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: _deskripsiCtrl, decoration: const InputDecoration(labelText: 'Deskripsi', isDense: true), maxLines: 2),
            const SizedBox(height: 10),
            TextField(controller: _htmlCtrl, decoration: const InputDecoration(labelText: 'HTML Konten', isDense: true), maxLines: 6),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _orientation,
              items: const [
                DropdownMenuItem(value: 'portrait', child: Text('Portrait')),
                DropdownMenuItem(value: 'landscape', child: Text('Landscape')),
              ],
              onChanged: (v) => setState(() => _orientation = v!),
              decoration: const InputDecoration(labelText: 'Orientation', isDense: true),
            ),
            const SizedBox(height: 10),
            Row(children: [Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v)), const SizedBox(width: 6), const Text('Aktif')]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            if (widget.isEdit) {
              ref.read(certTemplatesProvider.notifier).update(
                    id: widget.existing!.id, nama: _namaCtrl.text, deskripsi: _deskripsiCtrl.text.isEmpty ? null : _deskripsiCtrl.text,
                    htmlContent: _htmlCtrl.text, orientation: _orientation, isActive: _isActive,
                  );
            } else {
              ref.read(certTemplatesProvider.notifier).create(
                    nama: _namaCtrl.text, deskripsi: _deskripsiCtrl.text.isEmpty ? null : _deskripsiCtrl.text,
                    htmlContent: _htmlCtrl.text, orientation: _orientation, isActive: _isActive,
                  );
            }
            Navigator.pop(context);
          },
          child: Text(widget.isEdit ? 'Update' : 'Simpan'),
        ),
      ],
    );
  }
}

class _IssuedTab extends ConsumerWidget {
  const _IssuedTab();

  Future<void> _downloadPdf(BuildContext ctx, WidgetRef ref, IssuedCertificate cert) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = await ref.read(certificatesRepositoryProvider).downloadIssued(cert.id, '${dir.path}/sertifikat-${cert.id}.pdf');
      await OpenFilex.open(path);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('PDF didownload')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref, IssuedCertificate cert) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Hapus Sertifikat?'),
        content: Text('Sertifikat ${cert.nomorSertifikat} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(issuedCertificatesProvider.notifier).delete(cert.id);
              Navigator.pop(d);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(issuedCertificatesProvider);
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) return Center(child: Text('Gagal: ${state.error}', style: TextStyle(color: Colors.red[400])));
    if (state.issued.isEmpty) return const Center(child: Text('Belum ada sertifikat', style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      itemCount: state.issued.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final cert = state.issued[i];
        return ListTile(
          leading: const Icon(Icons.work_history, color: Color(0xFF0F766E)),
          title: Text(cert.nomorSertifikat, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${cert.studentName ?? cert.userId} • ${cert.namaKursus}${cert.tanggalLulus != null ? '\n${_fmtDate(cert.tanggalLulus!.toLocal())}' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(icon: const Icon(Icons.download, color: Color(0xFF0F766E)), onPressed: () => _downloadPdf(context, ref, cert)),
        );
      },
    );
  }
}

class _IssueForm extends ConsumerStatefulWidget {
  const _IssueForm();

  @override
  ConsumerState<_IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends ConsumerState<_IssueForm> {
  int? _userId;
  int? _templateId;
  final _kursusCtrl = TextEditingController();
  DateTime _tanggal = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(certTemplatesProvider).templates;
    _templateId ??= templates.isNotEmpty ? templates.first.id : null;

    return AlertDialog(
      title: const Text('Terbitkan Sertifikat'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _kursusCtrl, decoration: const InputDecoration(labelText: 'Nama Kursus', isDense: true)),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: 'Tanggal Lulus', hintText: _fmtDate(_tanggal), isDense: true),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _tanggal, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (picked != null) setState(() => _tanggal = picked);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'User ID', hintText: 'Masukkan ID user', isDense: true),
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => _userId = int.tryParse(v)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _templateId,
              items: templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nama))).toList(),
              onChanged: (v) => setState(() => _templateId = v),
              decoration: const InputDecoration(labelText: 'Template', isDense: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _userId == null || _templateId == null || _kursusCtrl.text.isEmpty
              ? null
              : () {
                  ref.read(issuedCertificatesProvider.notifier).issue(
                        userId: _userId!,
                        templateId: _templateId!,
                        namaKursus: _kursusCtrl.text,
                        tanggalLulus: _tanggal,
                      );
                  Navigator.pop(context);
                },
          child: const Text('Terbitkan'),
        ),
      ],
    );
  }
}
