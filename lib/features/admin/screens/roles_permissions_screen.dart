import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/role_permission_model.dart';
import '../providers/roles_permissions_provider.dart';

const _protectedRoles = ['admin', 'student', 'mentor', 'guest', 'fulltimer'];

class RolesPermissionsScreen extends ConsumerStatefulWidget {
  const RolesPermissionsScreen({super.key});

  @override
  ConsumerState<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends ConsumerState<RolesPermissionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(rolesPermissionsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolesPermissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Roles & Permissions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoleForm(context),
        child: const Icon(Icons.add),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Text('Gagal memuat: ${state.error}',
                      style: TextStyle(color: Colors.red[400])))
              : state.roles.isEmpty
                  ? const Center(child: Text('Tidak ada role', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(rolesPermissionsProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.roles.length,
                        itemBuilder: (context, i) => _RoleCard(role: state.roles[i]),
                      ),
                    ),
    );
  }

  void _showRoleForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama role (huruf kecil, angka, underscore)',
                hintText: 'contoh: koordinator',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await ref
                  .read(rolesPermissionsProvider.notifier)
                  .createRole(name: name, description: descCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Role ditambahkan' : 'Gagal menambahkan role')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  final RoleModel role;
  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isProtected = _protectedRoles.contains(role.name);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(role.name,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (isProtected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_outline, size: 14, color: Colors.grey[500]),
                      ],
                    ],
                  ),
                ),
                Text('${role.usersCount} pengguna',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showActions(context, ref),
                ),
              ],
            ),
            if (role.description != null && role.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(role.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: role.permissions.isEmpty
                  ? [const Text('Belum ada permission', style: TextStyle(fontSize: 12, color: Colors.grey))]
                  : role.permissions
                      .map((p) => Chip(
                            label: Text(p.name, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ))
                      .toList(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Kelola Permission'),
                onPressed: () => _showPermissionEditor(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final isProtected = _protectedRoles.contains(role.name);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Role'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditForm(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('Kelola Permission'),
              onTap: () {
                Navigator.pop(ctx);
                _showPermissionEditor(context, ref);
              },
            ),
            ListTile(
              enabled: !isProtected,
              leading: Icon(Icons.delete_outline, color: isProtected ? Colors.grey : Colors.red),
              title: Text('Hapus Role',
                  style: TextStyle(color: isProtected ? Colors.grey : Colors.red)),
              subtitle: isProtected ? const Text('Role bawaan tidak dapat dihapus') : null,
              onTap: isProtected
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, ref);
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditForm(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: role.name);
    final descCtrl = TextEditingController(text: role.description ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama role')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await ref
                  .read(rolesPermissionsProvider.notifier)
                  .updateRole(role.id, name: name, description: descCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Role diperbarui' : 'Gagal memperbarui role')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showPermissionEditor(BuildContext context, WidgetRef ref) {
    final allPermissions = ref.read(rolesPermissionsProvider).permissions;
    final selected = Set<int>.from(role.permissionIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) => SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Permission untuk "${role.name}"',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Expanded(
                  child: allPermissions.isEmpty
                      ? const Center(child: Text('Tidak ada permission tersedia'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: allPermissions.length,
                          itemBuilder: (context, i) {
                            final p = allPermissions[i];
                            return CheckboxListTile(
                              value: selected.contains(p.id),
                              title: Text(p.name),
                              subtitle: p.description != null ? Text(p.description!) : null,
                              onChanged: (v) {
                                setSheetState(() {
                                  if (v == true) {
                                    selected.add(p.id);
                                  } else {
                                    selected.remove(p.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final ok = await ref
                            .read(rolesPermissionsProvider.notifier)
                            .syncPermissions(role.id, selected.toList());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Permission disimpan' : 'Gagal menyimpan permission')),
                          );
                        }
                      },
                      child: const Text('Simpan Permission'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Role?'),
        content: Text('Role "${role.name}" akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(rolesPermissionsProvider.notifier).deleteRole(role.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Role dihapus' : 'Gagal menghapus role')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
