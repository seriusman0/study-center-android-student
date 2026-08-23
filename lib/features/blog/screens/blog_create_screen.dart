import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/blog_provider.dart';

class BlogCreateScreen extends ConsumerStatefulWidget {
  const BlogCreateScreen({super.key});

  @override
  ConsumerState<BlogCreateScreen> createState() => _BlogCreateScreenState();
}

class _BlogCreateScreenState extends ConsumerState<BlogCreateScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Backend requires cabang_id — take it from the logged-in user's own
    // cabang (BlogController::store validates it as required|exists).
    final cabangId = ref.read(authProvider).user?.cabangId;
    if (cabangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun Anda belum terkait cabang, tidak bisa membuat artikel.')),
      );
      return;
    }

    final ok = await ref.read(blogCreateProvider.notifier).create(
          title:    _titleCtrl.text.trim(),
          body:     _bodyCtrl.text.trim(),
          cabangId: cabangId,
        );

    if (!mounted) return;

    if (ok) {
      final slug = ref.read(blogCreateProvider).createdSlug;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artikel berhasil dipublikasikan!')),
      );
      if (slug != null) {
        context.go('/blog/$slug');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blogCreateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tulis Artikel'),
        actions: [
          TextButton(
            onPressed: state.loading ? null : _submit,
            child: state.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publikasikan'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child:
                        Text(state.error!, style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Judul artikel...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Judul diperlukan';
                    if (v.trim().length < 5) return 'Judul minimal 5 karakter';
                    return null;
                  },
                ),
                const Divider(),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _bodyCtrl,
                  minLines: 12,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Tulis konten artikel di sini...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Konten diperlukan';
                    if (v.trim().length < 20) return 'Konten terlalu pendek';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
