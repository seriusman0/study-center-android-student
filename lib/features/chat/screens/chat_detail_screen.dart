import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_detail_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String title;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.title = 'Chat',
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(chatDetailProvider(widget.conversationId).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatMessageTime(String isoString) {
    if (isoString.isEmpty) return '';
    final date = DateTime.tryParse(isoString);
    if (date == null) return '';
    
    // Parse as UTC (if not already parsed as UTC) and convert to local time
    final utcDate = date.isUtc ? date : DateTime.utc(date.year, date.month, date.day, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
    final local = utcDate.toLocal();
    final now = DateTime.now();

    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final monthName = months[local.month - 1];
      return '${local.day} $monthName';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatDetailProvider(widget.conversationId));
    final me = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            if (state.typingUserName.isNotEmpty)
              Text(
                '${state.typingUserName} sedang mengetik...',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.loading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: state.messages.length + (state.loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ));
                      }

                      final msg = state.messages[index];
                      final isMe = msg.userId == me?.id;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe && msg.user != null)
                                Text(
                                  msg.user!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              if (msg.type == 'image' && msg.attachmentUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Image.network(
                                    msg.thumbnailUrl ?? msg.attachmentUrl!,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (msg.body != null && msg.body!.isNotEmpty)
                                Text(msg.body!),
                              const SizedBox(height: 4),
                              Text(
                                _formatMessageTime(msg.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.teal.shade800 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (_) {
                      if (me != null) {
                        ref.read(chatDetailProvider(widget.conversationId).notifier).sendTyping(me.id, me.name);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Kirim Pesan',
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        ref.read(chatDetailProvider(widget.conversationId).notifier).sendTextMessage(text);
                        _textController.clear();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
