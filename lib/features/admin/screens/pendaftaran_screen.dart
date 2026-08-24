import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pendaftaran_model.dart';
import '../providers/pendaftaran_provider.dart';

/// Admin: validasi pendaftaran siswa baru (pending → diterima/ditolak/perbaikan).
/// List dengan filter status + search, tap ke detail, validasi via tombol aksi.
class PendaftaranScreen extends ConsumerStatefulWidget {
  const PendaftaranScreen({super.key});

  @override
  ConsumerState<PendaftaranScreen> createState() => _PendaftaranScreenState();
}

class _PendaftaranScreenState extends ConsumerState<PendaftaranScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pendaftaranListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendaftaranListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Pendaftaran')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama/username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onSubmitted: (v) => ref.read(pendaftaranListProvider.notifier).load(query: v),
            )),
          Wrap(
            spacing: 6,
            children: ['semua', 'pending', 'diterima', 'ditolak', 'perbaikan']
                .map((s) => ChoiceChip(
                      label: Text(s.toUpperCase(), style: TextStyle(fontSize: 11, color: state.statusFilter == s ? Colors.white : Colors.grey[700])),
                      selected: state.statusFilter == s,
                      onSelected: (_) => ref.read(pendaftaranListProvider.notifier).load(status: s),
                      selectedColor: const Color(0xFF0F766E),
                      backgroundColor: Colors.grey[100],
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Gagal: ${state.error}', style: TextStyle(color: Colors.red[400])))
                    : state.items.isEmpty
                        ? const Center(child: Text('Tidak ada pendaftaran', style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: state.items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = state.items[i];
                              final status = item.profile?.status ?? 'pending';
                              final statusColor = switch (status) {
                                'diterima' => Colors.green,
                                'ditolak' => Colors.red,
                                'perbaikan' => Colors.orange,
                                _ => Colors.grey,
                              };
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: item.avatar != null ? NetworkImage(item.avatar!) : null,
                                  child: item.avatar == null ? Text(item.name[0].toUpperCase()) : null,
                                ),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('@${item.username}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                                  ),
                                ]),
                                trailing: const Icon(Icons.chevron_right, size: 18),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PendaftaranDetailScreen(userId: item.id, userName: item.name))),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class PendaftaranDetailScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userName;

  const PendaftaranDetailScreen({super.key, required this.userId, required this.userName});

  @override
  ConsumerState<PendaftaranDetailScreen> createState() => _PendaftaranDetailScreenState();
}

class _PendaftaranDetailScreenState extends ConsumerState<PendaftaranDetailScreen> {
  final _catatanCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pendaftaranDetailProvider(widget.userId).notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendaftaranDetailProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: Text('Validasi — ${widget.userName}')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Gagal: ${state.error}'))
              : state.item == null
                  ? const SizedBox.shrink()
                  : _DetailView(item: state.item!, state: state, catatanCtrl: _catatanCtrl),
    );
  }
}

class _DetailView extends ConsumerWidget {
  final PendaftaranItem item;
  final PendaftaranDetailState state;
  final TextEditingController catatanCtrl;

  const _DetailView({required this.item, required this.state, required this.catatanCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = item.profile;
    final status = p?.status ?? 'pending';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.avatar != null) CircleAvatar(backgroundImage: NetworkImage(item.avatar!), radius: 40),
          const SizedBox(height: 12),
          Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text('@${item.username}', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          if (p != null) ...[
            _field('Tempat/Tanggal Lahir', '${p.birthPlace ?? '-'} / ${p.birthDate ?? '-'}'),
            _field('Jenis Kelamin', p.gender?.toUpperCase() ?? '-'),
            _field('Alamat', p.address ?? '-'),
            _field('No. HP Siswa', p.studentPhone ?? '-'),
            _field('Nama Wali', p.guardianName ?? '-'),
            _field('No. HP Wali', p.guardianPhone ?? '-'),
            _field('Sekolah', p.schoolName ?? '-'),
            _field('Kelas', p.gradeClass ?? '-'),
            _field('Tahun Masuk', p.entryYear?.toString() ?? '-'),
            _field('Mata Pelajaran', p.mataPelajaran.join(', ')),
            if (p.photo != null) ...[
              const SizedBox(height: 8),
              Text('Foto', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Image.network(p.photo!, width: 120, height: 120, fit: BoxFit.cover),
            ],
            if (p.catatanAdmin != null && p.catatanAdmin!.isNotEmpty)
              _field('Catatan Admin Sebelumnya', p.catatanAdmin!),
          ],
          const SizedBox(height: 16),
          Text('Status: $status', style: TextStyle(fontWeight: status == 'diterima' ? FontWeight.w700 : FontWeight.normal)),
          if (p?.status == 'perbaikan' && p?.catatanAdmin != null)
            Text('Catatan: ${p!.catatanAdmin}', style: TextStyle(color: Colors.orange[700]),),
          const SizedBox(height: 20),
          if (status != 'diterima') ...[
            Text('Validasi', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: catatanCtrl, decoration: const InputDecoration(labelText: 'Catatan admin', hintText: 'Opsional'), maxLines: 3)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              ElevatedButton.icon(onPressed: state.submitting ? null : () => _validasi(context, ref, 'diterima'), icon: const Icon(Icons.check), label: const Text('Diterima')),
              ElevatedButton.icon(onPressed: state.submitting ? null : () => _validasi(context, ref, 'ditolak'), icon: const Icon(Icons.close), label: const Text('Ditolak'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red)),
              ElevatedButton.icon(onPressed: state.submitting ? null : () => _validasi(context, ref, 'perbaikan'), icon: const Icon(Icons.edit), label: const Text('Perbaikan'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[50], foregroundColor: Colors.orange[700])),
            ]),
          ] else
            const Text('Pendaftaran ini sudah diterima.', style: TextStyle(color: Colors.green)),
          if (state.submitting) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 14)),
      ]),
    );
  }

  void _validasi(BuildContext ctx, WidgetRef ref, String status) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Konfirmasi: $status'),
        content: Text('Pendaftaran ini akan ditandai sebagai $status.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(pendaftaranDetailProvider(item.id).notifier).validasi(status: status, catatanAdmin: catatanCtrl.text.isEmpty ? null : catatanCtrl.text);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(ok ? 'Berhasil' : 'Gagal')));
            },
            child: Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }
}
