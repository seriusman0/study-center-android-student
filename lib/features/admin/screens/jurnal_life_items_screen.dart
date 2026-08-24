import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/jurnal_config_model.dart';
import '../providers/jurnal_life_items_provider.dart';

class JurnalLifeItemsScreen extends ConsumerStatefulWidget {
  const JurnalLifeItemsScreen({super.key});

  @override
  ConsumerState<JurnalLifeItemsScreen> createState() => _JurnalLifeItemsScreenState();
}

class _JurnalLifeItemsScreenState extends ConsumerState<JurnalLifeItemsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(jurnalLifeItemsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jurnalLifeItemsProvider);
    final theme = Theme.of(context);

    // Group items by kategori, preserving first-seen order.
    final grouped = <String, List<JurnalLifeItem>>{};
    for (final item in state.items) {
      grouped.putIfAbsent(item.kategori, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Item Jurnal Kehidupan')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(jurnalLifeItemsProvider.notifier).load(),
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
                              child: Text('Belum ada item jurnal',
                                  style: TextStyle(color: Colors.grey))),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 90, top: 8),
                        children: grouped.entries
                            .map((entry) => _KategoriSection(
                                  kategori: entry.key,
                                  items: entry.value,
                                  onEdit: (item) => _showForm(context, item: item),
                                  onToggle: (item) => ref
                                      .read(jurnalLifeItemsProvider.notifier)
                                      .toggleActive(item),
                                  onDelete: (item) => _confirmDelete(context, item),
                                ))
                            .toList(),
                      ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, JurnalLifeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item?'),
        content: Text('Item "${item.label}" akan dihapus permanen.'),
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
      final ok = await ref.read(jurnalLifeItemsProvider.notifier).delete(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Item dihapus' : 'Gagal menghapus item')),
        );
      }
    }
  }

  Future<void> _showForm(BuildContext context, {JurnalLifeItem? item}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LifeItemFormSheet(item: item),
    );
  }
}

class _KategoriSection extends StatelessWidget {
  final String kategori;
  final List<JurnalLifeItem> items;
  final ValueChanged<JurnalLifeItem> onEdit;
  final ValueChanged<JurnalLifeItem> onToggle;
  final ValueChanged<JurnalLifeItem> onDelete;

  const _KategoriSection({
    required this.kategori,
    required this.items,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            kategori.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text(item.label,
                    style: TextStyle(
                      decoration: item.isActive ? null : TextDecoration.lineThrough,
                      color: item.isActive ? null : Colors.grey,
                    )),
                subtitle: Text(item.isDefault ? 'Default' : 'Opsional',
                    style: const TextStyle(fontSize: 11)),
                leading: Icon(
                  item.isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: item.isActive ? Colors.green : Colors.grey,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showActions(context, item),
                ),
                onTap: () => _showActions(context, item),
              ),
            )),
      ],
    );
  }

  void _showActions(BuildContext context, JurnalLifeItem item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Item'),
              onTap: () {
                Navigator.pop(ctx);
                onEdit(item);
              },
            ),
            ListTile(
              leading: Icon(item.isActive ? Icons.block : Icons.check_circle_outline,
                  color: item.isActive ? Colors.red : Colors.green),
              title: Text(item.isActive ? 'Nonaktifkan' : 'Aktifkan'),
              onTap: () {
                Navigator.pop(ctx);
                onToggle(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LifeItemFormSheet extends ConsumerStatefulWidget {
  final JurnalLifeItem? item;
  const _LifeItemFormSheet({this.item});

  @override
  ConsumerState<_LifeItemFormSheet> createState() => _LifeItemFormSheetState();
}

class _LifeItemFormSheetState extends ConsumerState<_LifeItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kategoriCtrl;
  late final TextEditingController _labelCtrl;
  late bool _isDefault;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _kategoriCtrl = TextEditingController(text: widget.item?.kategori ?? '');
    _labelCtrl = TextEditingController(text: widget.item?.label ?? '');
    _isDefault = widget.item?.isDefault ?? false;
    _isActive = widget.item?.isActive ?? true;
  }

  @override
  void dispose() {
    _kategoriCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final newItem = JurnalLifeItem(
      id: widget.item?.id ?? 0,
      kategori: _kategoriCtrl.text.trim(),
      label: _labelCtrl.text.trim(),
      isDefault: _isDefault,
      isActive: _isActive,
    );

    final notifier = ref.read(jurnalLifeItemsProvider.notifier);
    final ok = widget.item == null
        ? await notifier.create(newItem)
        : await notifier.update(widget.item!.id, newItem);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan item')),
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
              Text(isEdit ? 'Edit Item Jurnal' : 'Tambah Item Jurnal',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kategoriCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'mis. kerohanian, pendidikan, karakter',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Kategori wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'mis. Baca Alkitab',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Label wajib diisi' : null,
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Item Default'),
                subtitle: const Text('Otomatis dicentang untuk siswa baru', style: TextStyle(fontSize: 11)),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                subtitle: const Text('Tampil di jurnal siswa', style: TextStyle(fontSize: 11)),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
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
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
