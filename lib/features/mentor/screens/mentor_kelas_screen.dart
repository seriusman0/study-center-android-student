import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/kelas_master_model.dart';
import '../providers/kelas_master_provider.dart';

class MentorKelasScreen extends ConsumerStatefulWidget {
  const MentorKelasScreen({super.key});

  @override
  ConsumerState<MentorKelasScreen> createState() => _MentorKelasScreenState();
}

class _MentorKelasScreenState extends ConsumerState<MentorKelasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(kelasMasterProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kelasMasterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelas Master')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditSheet(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(kelasMasterProvider.notifier).load(),
        child: state.loading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text('Gagal memuat kelas',
                            style: TextStyle(color: Colors.red[400])),
                      ),
                    ],
                  )
                : state.items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(
                              child: Text('Belum ada kelas',
                                  style: TextStyle(color: Colors.grey))),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length,
                        itemBuilder: (ctx, i) {
                          final k = state.items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(k.nama,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text([
                                if (k.cabang != null) k.cabang!,
                                if (k.keterangan != null && k.keterangan!.isNotEmpty)
                                  k.keterangan!,
                              ].join(' • ')),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!k.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text('Nonaktif',
                                          style: TextStyle(fontSize: 11)),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showEditSheet(context, existing: k),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 20, color: Colors.red[300]),
                                    onPressed: () => _confirmDelete(context, k),
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

  void _confirmDelete(BuildContext context, KelasMaster k) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kelas'),
        content: Text('Yakin ingin menghapus "${k.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(kelasMasterProvider.notifier).delete(k.id);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Gagal menghapus — mungkin masih dipakai di presensi')),
                );
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, {KelasMaster? existing}) {
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final ketCtrl = TextEditingController(text: existing?.keterangan ?? '');
    final user = ref.read(authProvider).user;
    final cabangId = existing?.cabangId ?? user?.cabangId ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(existing == null ? 'Tambah Kelas' : 'Edit Kelas',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kelas'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ketCtrl,
              decoration: const InputDecoration(labelText: 'Keterangan (opsional)'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (namaCtrl.text.trim().isEmpty || cabangId == 0) return;
                Navigator.pop(ctx);
                final notifier = ref.read(kelasMasterProvider.notifier);
                final ok = existing == null
                    ? await notifier.create(
                        nama: namaCtrl.text.trim(),
                        cabangId: cabangId,
                        keterangan: ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
                      )
                    : await notifier.update(
                        id: existing.id,
                        nama: namaCtrl.text.trim(),
                        cabangId: cabangId,
                        keterangan: ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
                        isActive: existing.isActive,
                      );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Gagal menyimpan kelas')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
