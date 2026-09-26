import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/jurnal_offline_model.dart';
import '../providers/jurnal_offline_provider.dart';

/// Admin screen for managing offline jurnal templates + photo scans.
///
/// Mirrors the navigation/styling conventions of [JurnalLifeItemsScreen]:
/// a teal AppBar, RefreshIndicator list, and a FloatingActionButton for
/// adding new templates. Uses two tabs — "Template" and "Photo Scan".
class JurnalOfflineScreen extends ConsumerStatefulWidget {
  const JurnalOfflineScreen({super.key});

  @override
  ConsumerState<JurnalOfflineScreen> createState() =>
      _JurnalOfflineScreenState();
}

class _JurnalOfflineScreenState extends ConsumerState<JurnalOfflineScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(jurnalOfflineTemplatesProvider.notifier).load();
      ref.read(jurnalPhotoScansProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesState = ref.watch(jurnalOfflineTemplatesProvider);
    final scansState = ref.watch(jurnalPhotoScansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template & Scan Jurnal Offline'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Template'),
            Tab(text: 'Photo Scan'),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          // Only show FAB on the Template tab (no "add" for scans — they
          // come from students).
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _tabController.index == 0
                ? FloatingActionButton(
                    key: const ValueKey('template-fab'),
                    backgroundColor: theme.colorScheme.primary,
                    onPressed: () => _showAddTemplateDialog(context),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : const SizedBox.shrink(key: ValueKey('scan-fab')),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Templates tab ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () =>
                ref.read(jurnalOfflineTemplatesProvider.notifier).load(),
            child: _buildTemplateList(templatesState, theme),
          ),
          // ── Photo Scans tab ────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () =>
                ref.read(jurnalPhotoScansProvider.notifier).load(),
            child: _buildScanList(scansState, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(
    JurnalOfflineTemplatesState state,
    ThemeData theme,
  ) {
    if (state.loading && state.templates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.templates.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Icon(Icons.error, color: Colors.red, size: 48)),
          SizedBox(height: 16),
          Center(child: Text('Gagal memuat data')),
        ],
      );
    }
    if (state.templates.isEmpty) {
      return const Center(child: Text('Belum ada data'));
    }
    return ListView.separated(
      itemCount: state.templates.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) =>
          _buildTemplateTile(ctx, state.templates[i], theme),
    );
  }

  Widget _buildScanList(
    JurnalPhotoScansState state,
    ThemeData theme,
  ) {
    if (state.loading && state.scans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.scans.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Icon(Icons.error, color: Colors.red, size: 48)),
          SizedBox(height: 16),
          Center(child: Text('Gagal memuat data')),
        ],
      );
    }
    if (state.scans.isEmpty) {
      return const Center(child: Text('Belum ada data'));
    }
    return ListView.separated(
      itemCount: state.scans.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) =>
          _buildScanTile(ctx, state.scans[i], theme),
    );
  }

  Widget _buildTemplateTile(
    BuildContext context,
    JurnalOfflineTemplate template,
    ThemeData theme,
  ) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.teal,
        child: Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
      title: Text(template.originalName,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cabang: ${template.cabangNama}',
              style: theme.textTheme.bodySmall),
          Text('Di-upload: ${template.uploadedByName}',
              style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.teal),
            tooltip: 'Unduh',
            onPressed: () => _downloadTemplate(template.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Hapus',
            onPressed: () => _deleteTemplate(template.id),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTile(
    BuildContext context,
    JurnalPhotoScan scan,
    ThemeData theme,
  ) {
    final statusColor = switch (scan.status) {
      JurnalPhotoScanStatus.pending => Colors.orange,
      JurnalPhotoScanStatus.processing => Colors.blue,
      JurnalPhotoScanStatus.success => Colors.green,
      JurnalPhotoScanStatus.failed => Colors.red,
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.2),
        child: Icon(Icons.image, color: statusColor),
      ),
      title: Text(scan.originalName,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Chip(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        label: Text(scan.status.label,
            style: TextStyle(color: statusColor, fontSize: 12)),
      ),
    );
  }

  void _showAddTemplateDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final cabangCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Template Offline'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: cabangCtrl,
                decoration: const InputDecoration(labelText: 'ID Cabang'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              const Text(
                  'File PDF template akan dipilih di versi berikutnya (gunakan endpoint manual untuk sekarang).',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // Placeholder — upload via file picker will be wired once
                // file_picker/image_picker is confirmed available.
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Silakan upload PDF via endpoint langsung')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTemplate(int id) async {
    final url = await ref
        .read(jurnalOfflineRepositoryProvider)
        .downloadTemplate(id);
    if (mounted && url.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL unduh: $url')),
      );
    }
  }

  Future<void> _deleteTemplate(int id) async {
    final ok =
        await ref.read(jurnalOfflineTemplatesProvider.notifier).delete(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Template berhasil dihapus'
              : 'Gagal menghapus template'),
        ),
      );
    }
  }
}
