import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_list_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan'),
      ),
      body: state.loading && state.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.conversations.isEmpty
                  ? const Center(child: Text('Belum ada pesan.'))
                  : ListView.builder(
                        itemCount: state.conversations.length,
                        itemBuilder: (context, index) {
                          final conv = state.conversations[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(conv.displayName.isNotEmpty ? conv.displayName[0] : '?'),
                            ),
                            title: Text(
                              conv.displayName,
                              style: TextStyle(
                                fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              conv.lastMessage?.body ?? (conv.lastMessage?.type == 'image' ? '📷 Foto' : ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: conv.unreadCount > 0
                                ? CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      '${conv.unreadCount}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              context.push('/chat/${conv.id}', extra: conv.displayName);
                            },
                          );
                        },
                      ),
    );
  }
}
