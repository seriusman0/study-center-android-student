import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/blog_moderation_provider.dart';

/// Admin: moderate blog posts and comments across all branches.
/// Tab 1 = semua blog (hapus), Tab 2 = semua komentar (hapus).
class BlogModerationScreen extends ConsumerStatefulWidget {
  const BlogModerationScreen({super.key});

  @override
  ConsumerState<BlogModerationScreen> createState() => _BlogModerationScreenState();
}

class _BlogModerationScreenState extends ConsumerState<BlogModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(blogModerationProvider.notifier).loadBlogs();
      ref.read(blogModerationProvider.notifier).loadComments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blogModerationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderasi Blog & Komentar'),
        bottom: const TabBar(tabs: [Tab(text: 'Blog'), Tab(text: 'Komentar')]),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari blog/komentar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onSubmitted: (v) {
                if (_tabController.index == 0) {
                  ref.read(blogModerationProvider.notifier).loadBlogs(search: v);
                } else {
                  // comments search not directly supported but search term kept for future
                }
              },
            )),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_BlogsTab(), _CommentsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlogsTab extends ConsumerWidget {
  const _BlogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blogModerationProvider);
    if (state.loadingBlogs) return const Center(child: CircularProgressIndicator());
    if (state.blogsError != null)
      return Center(child: Text('Gagal: ${state.blogsError}', style: TextStyle(color: Colors.red[400])));
    if (state.blogs.isEmpty) return const Center(child: Text('Tidak ada blog', style: TextStyle(color: Colors.grey)));

    return RefreshIndicator(
      onRefresh: () => ref.read(blogModerationProvider.notifier).loadBlogs(),
      child: ListView.separated(
        itemCount: state.blogs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final blog = state.blogs[i];
          return ListTile(
            leading: const Icon(Icons.article, color: Color(0xFF0F766E)),
            title: Text(blog.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(blog.authorName ?? 'Admin', style: TextStyle(fontSize: 11, color: Colors.grey)),
              if (blog.cabangNama != null) Text(blog.cabangNama!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              tooltip: 'Hapus Blog',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Blog?'),
                    content: Text('Blog "${blog.title}" akan dihapus? Tindakan ini tidak bisa dibatalkan.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(blogModerationProvider.notifier).deleteBlog(blog.id);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CommentsTab extends ConsumerWidget {
  const _CommentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blogModerationProvider);
    if (state.loadingComments) return const Center(child: CircularProgressIndicator());
    if (state.commentsError != null)
      return Center(child: Text('Gagal: ${state.commentsError}', style: TextStyle(color: Colors.red[400])));
    if (state.comments.isEmpty) return const Center(child: Text('Tidak ada komentar', style: TextStyle(color: Colors.grey)));

    return RefreshIndicator(
      onRefresh: () => ref.read(blogModerationProvider.notifier).loadComments(),
      child: ListView.separated(
        itemCount: state.comments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final comment = state.comments[i];
          return ListTile(
            leading: const Icon(Icons.comment, color: Color(0xFF0F766E)),
            title: Text(comment.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (comment.userName != null)
                  Text('Oleh: ${comment.userName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (comment.blogTitle != null)
                  Text('Di: ${comment.blogTitle}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (comment.createdAt != null)
                  Text(comment.createdAt!, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              tooltip: 'Hapus Komentar',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Komentar?'),
                    content: const Text('Komentar ini akan dihapus? Tindakan ini tidak bisa dibatalkan.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(blogModerationProvider.notifier).deleteComment(comment.id);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
