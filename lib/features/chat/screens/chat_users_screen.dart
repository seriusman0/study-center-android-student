import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_users_provider.dart';

class ChatUsersScreen extends ConsumerWidget {
  const ChatUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatUsersProvider);
    final notifier = ref.read(chatUsersProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mulai Chat Baru'),
      ),
      body: state.loading && state.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.users.isEmpty
                  ? const Center(child: Text('Tidak ada pengguna yang tersedia.'))
                  : ListView.builder(
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                          ),
                          title: Text(user.name),
                          onTap: () async {
                            final convId = await notifier.startPrivateChat(user.id);
                            if (convId != null && context.mounted) {
                              context.replace('/chat/$convId', extra: user.name);
                            } else if (state.error != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.error!)),
                              );
                            }
                          },
                        );
                      },
                    ),
    );
  }
}
