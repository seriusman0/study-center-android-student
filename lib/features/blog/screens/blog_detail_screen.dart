import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/blog_model.dart';
import '../providers/blog_provider.dart';

class BlogDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const BlogDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl  = ScrollController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(blogDetailProvider(widget.slug).notifier)
        .postComment(text);

    if (ok && mounted) {
      _commentCtrl.clear();
      // Scroll to end after a short delay to let list rebuild
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(blogDetailProvider(widget.slug));
    final authUser = ref.watch(authProvider).user;
    final theme    = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.blog?.title ?? 'Artikel'),
        actions: [
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
      body: () {
        if (state.loading && state.blog == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.blog == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(blogDetailProvider(widget.slug).notifier)
                      .load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ]),
            ),
          );
        }

        final blog = state.blog!;
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(blogDetailProvider(widget.slug).notifier).load(),
                child: ListView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.zero,
                  children: [
                    // Hero image
                    if (blog.image != null)
                      CachedNetworkImage(
                        imageUrl: blog.image!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 220,
                          color: Colors.grey[200],
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 220,
                          color: Colors.grey[200],
                          child: Icon(Icons.image,
                              size: 48, color: Colors.grey[400]),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            blog.title,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),

                          // Meta row
                          Row(
                            children: [
                              if (blog.authorAvatar != null)
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage:
                                      NetworkImage(blog.authorAvatar!),
                                )
                              else
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.15),
                                  child: Text(
                                    (blog.authorName ?? 'A')[0].toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.primary),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (blog.authorName != null)
                                      Text(blog.authorName!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                    if (blog.publishedAt != null)
                                      Text(
                                        _formatDate(blog.publishedAt!),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: Colors.grey[500]),
                                      ),
                                  ],
                                ),
                              ),
                              if (blog.cabangNama != null)
                                Chip(
                                  label: Text(blog.cabangNama!,
                                      style:
                                          const TextStyle(fontSize: 11)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Body
                          if (blog.body != null && blog.body!.isNotEmpty)
                            Text(
                              blog.body!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(height: 1.7),
                            )
                          else
                            Text('Tidak ada konten.',
                                style:
                                    TextStyle(color: Colors.grey[500])),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Comments header
                          Row(
                            children: [
                              Icon(Icons.comment_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Komentar (${blog.comments.length})',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (blog.comments.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text('Belum ada komentar.',
                                  style:
                                      TextStyle(color: Colors.grey[500])),
                            )
                          else
                            ...blog.comments.map((c) => _CommentTile(
                                  comment:   c,
                                  canDelete: authUser != null,
                                  onDelete: () => ref
                                      .read(blogDetailProvider(widget.slug)
                                          .notifier)
                                      .deleteComment(c.id),
                                )),

                          if (state.error != null) ...[
                            const SizedBox(height: 8),
                            Text(state.error!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12)),
                          ],

                          // Bottom padding so the input doesn't overlap
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Comment input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  state.submittingComment
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: Icon(Icons.send,
                              color: theme.colorScheme.primary),
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ),
          ],
        );
      }(),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMM yyyy', 'id').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

class _CommentTile extends StatelessWidget {
  final BlogComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          comment.authorAvatar != null
              ? CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(comment.authorAvatar!),
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      theme.colorScheme.primary.withOpacity(0.15),
                  child: Text(
                    comment.authorName[0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.primary),
                  ),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (comment.createdAt != null)
                        Text(
                          _formatDate(comment.createdAt!),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      if (canDelete)
                        GestureDetector(
                          onTap: onDelete,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.close,
                                size: 14, color: Colors.grey[400]),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMM', 'id').format(dt);
    } catch (_) {
      return '';
    }
  }
}
