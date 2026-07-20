import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final jState = ref.read(journalProvider);
      if (jState.snapshot == null && !jState.loading) {
        ref.read(journalProvider.notifier).load();
      }
      final hState = ref.read(homeProvider);
      if (!hState.loading && hState.blogs.isEmpty && hState.laporan == null) {
        final user = ref.read(authProvider).user;
        ref.read(homeProvider.notifier).load(user?.cabangSlug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(authProvider).user;
    final jState = ref.watch(journalProvider);
    final hState = ref.watch(homeProvider);
    final snap   = jState.snapshot;
    final theme  = Theme.of(context);
    final now    = DateTime.now();

    String greeting() {
      final h = now.hour;
      if (h < 11) return 'Selamat pagi';
      if (h < 15) return 'Selamat siang';
      if (h < 18) return 'Selamat sore';
      return 'Selamat malam';
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(journalProvider.notifier).load(),
            ref.read(homeProvider.notifier).load(user?.cabangSlug),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Text(
              '${greeting()},',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              user?.name ?? '',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id').format(now),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),

            const SizedBox(height: 24),

            // QR Code Absensi
            if (user != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.qr_code, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('QR Absensi', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: user.id.toString(),
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(user.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (user.cabang != null)
                        Text(user.cabang!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Jurnal Hari Ini
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Jurnal Hari Ini', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (jState.loading) const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (snap != null) ...[
                      LinearProgressIndicator(
                        value: snap.totalCount > 0 ? snap.checkedCount / snap.totalCount : 0,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snap.checkedCount} dari ${snap.totalCount} item selesai',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 14),
                      _BibleRow('PL', snap.bible.plPorsi, snap.bible.plChecked),
                      const SizedBox(height: 6),
                      _BibleRow('PB', snap.bible.pbPorsi, snap.bible.pbChecked),
                    ] else if (jState.error != null)
                      Text('Gagal memuat jurnal', style: TextStyle(color: Colors.red[400], fontSize: 13))
                    else
                      const Text('Memuat...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            // Streak
            if (hState.laporan != null && hState.laporan!.streak > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Streak ${hState.laporan!.streak} hari berturut-turut',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Verse reference
            if (snap != null && snap.verseRef != null && snap.verseRef!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote, color: theme.colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text('Hafal Ayat: ', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(snap.verseRef!, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Artikel Terbaru
            Row(
              children: [
                Icon(Icons.article, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Artikel Terbaru', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (hState.loading && hState.blogs.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (hState.blogs.isEmpty)
              Text('Belum ada artikel', style: TextStyle(color: Colors.grey[500]))
            else
              ...hState.blogs.map((blog) => _BlogCard(blog: blog, theme: theme)),

            const SizedBox(height: 24),

            // Galeri Kegiatan
            Row(
              children: [
                Icon(Icons.photo_library, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Galeri Kegiatan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (hState.loading && hState.galeri.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (hState.galeri.isEmpty)
              Text('Belum ada foto kegiatan', style: TextStyle(color: Colors.grey[500]))
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hState.galeri.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) => _GaleriCard(item: hState.galeri[i]),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BibleRow extends StatelessWidget {
  final String type;
  final String porsi;
  final bool checked;

  const _BibleRow(this.type, this.porsi, this.checked);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: checked ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text('$type — $porsi', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _BlogCard extends StatelessWidget {
  final dynamic blog;
  final ThemeData theme;

  const _BlogCard({required this.blog, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (blog.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: blog.image!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.article, color: Colors.grey[400]),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.article, color: theme.colorScheme.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (blog.publishedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(blog.publishedAt!),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                  if (blog.cabangNama != null)
                    Text(
                      blog.cabangNama!,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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

class _GaleriCard extends StatelessWidget {
  final dynamic item;

  const _GaleriCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: item.fotoUrl,
        width: 140,
        height: 160,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 140,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 140,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey[400], size: 40),
        ),
      ),
    );
  }
}
