import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/certificate_model.dart';
import '../providers/nametags_provider.dart';

/// Admin: generate printable name tags. List eligible students with
/// multi-select, tap Generate → server returns layout (size + selected
/// students) which is rendered client-side as a printable grid of tags.
class NameTagsScreen extends ConsumerStatefulWidget {
  const NameTagsScreen({super.key});

  @override
  ConsumerState<NameTagsScreen> createState() => _NameTagsScreenState();
}

class _NameTagsScreenState extends ConsumerState<NameTagsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(nameTagsProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nameTagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Name Tags')),
      floatingActionButton: state.selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: state.generating ? null : () => _showResultSheet(),
              label: const Text('Generate'),
              icon: state.generating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print),
            )
          : null,
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
              onSubmitted: (v) => ref.read(nameTagsProvider.notifier).load(q: v),
            )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(spacing: 6, children: [
              ChoiceChip(label: const Text('Semua'), selected: state.selectedIds.isEmpty, onSelected: (_) => ref.read(nameTagsProvider.notifier).clearSelection(), visualDensity: VisualDensity.compact),
              Text('${state.selectedIds.length} terpilih', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Gagal: ${state.error}', style: TextStyle(color: Colors.red[400])))
                    : state.students.isEmpty
                        ? const Center(child: Text('Tidak ada siswa', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: state.students.length,
                            itemBuilder: (context, i) {
                              final s = state.students[i];
                              final sel = state.selectedIds.contains(s.id);
                              return CheckboxListTile(
                                value: sel,
                                onChanged: (_) => ref.read(nameTagsProvider.notifier).toggleSelected(s.id),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                secondary: CircleAvatar(backgroundImage: s.avatar != null ? NetworkImage(s.avatar!) : null, radius: 14),
                                title: Text(s.name, style: const TextStyle(fontSize: 13)),
                                subtitle: s.cabangNama != null ? Text(s.cabangNama!, style: const TextStyle(fontSize: 11)) : null,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _GenerateResultSheet(),
    );
  }
}

class _GenerateResultSheet extends ConsumerStatefulWidget {
  const _GenerateResultSheet();

  @override
  ConsumerState<_GenerateResultSheet> createState() => _GenerateResultSheetState();
}

class _GenerateResultSheetState extends ConsumerState<_GenerateResultSheet> {
  final _widthCtrl = TextEditingController(text: '8.5');
  final _heightCtrl = TextEditingController(text: '5.5');
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nameTagsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Konfigurasi Cetak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _widthCtrl, decoration: const InputDecoration(labelText: 'Lebar (cm)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: _heightCtrl, decoration: const InputDecoration(labelText: 'Tinggi (cm)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            if (_submitting) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Sedang generate...'),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.print),
                  label: const Text('Generate Name Tags'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    final width = double.tryParse(_widthCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    if (width == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lebar dan tinggi harus diisi')));
      return;
    }
    setState(() => _submitting = true);
    final ok = await ref.read(nameTagsProvider.notifier).generate(widthCm: width, heightCm: height);
    setState(() => _submitting = false);
    if (!mounted) return;

    final state = ref.read(nameTagsProvider);
    if (ok && state.result != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name tags berhasil digenerate'), backgroundColor: Colors.green),
      );
    }
  }
}
