import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../providers/admin_users_provider.dart';

const _allRoles = ['admin', 'fulltimer', 'mentor', 'student', 'guest', 'scholarship_teenager', 'college'];
const _roleLabels = {
  'admin': 'Admin',
  'fulltimer': 'Fulltimer',
  'mentor': 'Mentor',
  'student': 'Siswa',
  'guest': 'Tamu',
  'scholarship_teenager': 'Beasiswa Remaja',
  'college': 'Mahasiswa',
};

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminUsersProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Pengguna')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama/username...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (v) => ref.read(adminUsersProvider.notifier).load(query: v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: state.roleFilter == null,
                  onTap: () => ref.read(adminUsersProvider.notifier).load(clearRole: true),
                ),
                ..._allRoles.map((r) => _FilterChip(
                      label: _roleLabels[r] ?? r,
                      selected: state.roleFilter == r,
                      onTap: () => ref.read(adminUsersProvider.notifier).load(role: r),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Text('Gagal memuat: ${state.error}',
                            style: TextStyle(color: Colors.red[400])))
                    : state.users.isEmpty
                        ? const Center(child: Text('Tidak ada pengguna', style: TextStyle(color: Colors.grey)))
                        : RefreshIndicator(
                            onRefresh: () => ref.read(adminUsersProvider.notifier).load(),
                            child: ListView.builder(
                              itemCount: state.users.length,
                              itemBuilder: (context, i) => _UserTile(user: state.users[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
        child: user.avatar == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?') : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '@${user.username} • ${_roleLabels[user.primaryRole] ?? user.primaryRole}'
        '${user.cabang != null ? " • ${user.cabang}" : ""}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showActions(context, ref),
      ),
      onTap: () => _showActions(context, ref),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Ubah Role'),
              onTap: () {
                Navigator.pop(ctx);
                _showRolePicker(context, ref);
              },
            ),
            ListTile(
              leading: Icon(user.isActive == false ? Icons.check_circle_outline : Icons.block,
                  color: user.isActive == false ? Colors.green : Colors.red),
              title: Text(user.isActive == false ? 'Aktifkan Pengguna' : 'Nonaktifkan Pengguna'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await ref.read(adminUsersProvider.notifier).toggleActive(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Status pengguna diperbarui' : 'Gagal memperbarui status')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRolePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pilih Role Baru', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ..._allRoles.map((r) => ListTile(
                  title: Text(_roleLabels[r] ?? r),
                  trailing: user.primaryRole == r ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await ref.read(adminUsersProvider.notifier).updateRole(user.id, r);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? 'Role diperbarui' : 'Gagal memperbarui role')),
                      );
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }
}
