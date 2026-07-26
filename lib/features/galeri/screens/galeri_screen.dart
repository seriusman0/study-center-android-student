import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../home/models/home_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
class _GaleriState {
  final List<GaleriItem> items;
  final bool loading;
  final String? error;

  const _GaleriState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  _GaleriState copyWith({
    List<GaleriItem>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      _GaleriState(
        items:   items   ?? this.items,
        loading: loading ?? this.loading,
        error:   clearError ? null : (error ?? this.error),
      );
}

class _GaleriNotifier extends AutoDisposeNotifier<_GaleriState> {
  @override
  _GaleriState build() {
    Future.microtask(load);
    return const _GaleriState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(ApiConstants.galeri);
      final data = res.data as Map<String, dynamic>;
      final list = (data['data'] as List? ?? []);
      final items = list
          .map((e) => GaleriItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = _GaleriState(items: items);
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }
}

final _galeriScreenProvider =
    NotifierProvider.autoDispose<_GaleriNotifier, _GaleriState>(
        _GaleriNotifier.new);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class GaleriScreen extends ConsumerWidget {
  const GaleriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_galeriScreenProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri Kegiatan'),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(_galeriScreenProvider.notifier).load(),
            ),
        ],
      ),
      body: () {
        if (state.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.items.isEmpty) {
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
                  onPressed: () =>
                      ref.read(_galeriScreenProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ]),
            ),
          );
        }
        if (state.items.isEmpty) {
          return Center(
            child: Text('Belum ada foto kegiatan.',
                style: TextStyle(color: Colors.grey[500])),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(_galeriScreenProvider.notifier).load(),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: state.items.length,
            itemBuilder: (ctx, i) =>
                _GaleriGridItem(item: state.items[i], theme: theme),
          ),
        );
      }(),
    );
  }
}

class _GaleriGridItem extends StatelessWidget {
  final GaleriItem item;
  final ThemeData theme;

  const _GaleriGridItem({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.fotoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey[200],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
              ),
            ),
            // Gradient overlay for date label
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  _formatDate(item.tanggal),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(_formatDate(item.tanggal),
              style: const TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: item.fotoUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white, size: 60),
            ),
          ),
        ),
      ),
    ));
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
