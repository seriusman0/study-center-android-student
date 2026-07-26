import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primary.withAlpha(30),
              backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: user.avatar == null
                  ? Text(user.name[0].toUpperCase(), style: TextStyle(fontSize: 36, color: theme.colorScheme.primary))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(user.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (user.cabang != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(user.cabang!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            ),
          ],
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                _InfoTile(icon: Icons.alternate_email, label: 'Username', value: user.username),
                const Divider(height: 1, indent: 56),
                _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
                if (user.cabang != null) ...[
                  const Divider(height: 1, indent: 56),
                  _InfoTile(icon: Icons.location_on_outlined, label: 'Cabang', value: user.cabang!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
            onPressed: () => context.push('/profile/edit'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600], size: 20),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
