import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mata_pelajaran_model.dart';
import '../providers/mata_pelajaran_provider.dart';

/// Admin: kelola mata pelajaran (CRUD, toggle aktif).
class MataPelajaranScreen extends ConsumerStatefulWidget {
  const MataPelajaranScreen({super.key});

  @override
  ConsumerState<MataPelajaranScreen> createState() => _MataPelajaranScreenState();
}

class _MataPelajaranScreenState extends ConsumerState<MataPelajaranScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mataPelajaranProvider.notifier).load());
  }

  void _showForm(BuildContext ctx, {MataPelajaranModel? existing}) {
    final isEdit = existing != null;
    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final urutanCtrl = TextEditingController(text: existing != null ? '${existing.urutan}' : '0');

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Mata Pelajaran', isDense: true), maxLines: 1),
              const SizedBox(height: 10),
              TextField(controller: urutanCtrl, decoration: const InputDecoration(labelText: 'Urutan', isDense: true), keyboardType: TextInputType.number),
          ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final item = MataPelajaranModel(id: existing?.id ?? 0, nama: namaCtrl.text, urutan: int.tryParse(urutanCtrl.text) ?? 0, isActive: existing?.isActive ?? true);
              if (isEdit) {
                ref.read(mataPelajaranProvider.notifier).update(item.id, nama: item.nama, urutan: item.urutan, isActive: item.isActive);
              } else {
                ref.read(mataPelajaranProvider.notifier).create(nama: item.nama, urutan: item.urutan);
              }
              Navigator.pop(dialogCtx);
            },
            child: Text(isEdit ? 'Update' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, MataPelajaranModel item) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Mata Pelajaran?'),
        content: Text('"${item.nama}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(mataPelajaranProvider.notifier).delete(item.id);
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
    final state = ref.watch(mataPelajaranProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mata Pelajaran')),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(context), child: const Icon(Icons.add)),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Gagal: ${state.error}', style: TextStyle(color: Colors.red[400])))
              : state.items.isEmpty
                  ? const Center(child: Text('Belum ada mata pelajaran', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final mp = state.items[i];
                        return ListTile(
                          leading: const Icon(Icons.subject, color: Color(0xFF0F766E)),
                          title: Text(mp.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Urutan: ${mp.urutan}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: Switch(
                            value: mp.isActive,
                            onChanged: (v) => ref.read(mataPelajaranProvider.notifier).update(mp.id, nama: mp.nama, urutan: mp.urutan, isActive: v),
                            activeColor: const Color(0xFF0F766E),
                          ),
                        );
                      }),
    );
  }
}
