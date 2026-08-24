import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_update_service.dart';

/// A slim banner shown at the top of the home screen when an update is
/// available. Three states:
///   1. Downloading → shows progress bar
///   2. Download complete → "Ketuk untuk instal" button
///   3. Dismissed → hidden until next app launch
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);

    // Nothing to show.
    if (!state.updateAvailable && !state.downloading && !state.downloadComplete) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.system_update, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.downloadComplete
                      ? 'Pembaruan siap diinstal'
                      : state.downloading
                          ? 'Mengunduh pembaruan...'
                          : 'Versi ${state.info?.latestVersion ?? ""} tersedia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!state.downloading)
                GestureDetector(
                  onTap: () => ref.read(appUpdateProvider.notifier).dismiss(),
                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
            ],
          ),
          if (state.downloading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.downloadProgress > 0 ? state.downloadProgress : null,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(state.downloadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (state.downloadComplete) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(appUpdateProvider.notifier).installUpdate(),
                icon: const Icon(Icons.install_mobile, size: 18),
                label: const Text('Instal Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          if (state.info?.releaseNotes != null &&
              state.info!.releaseNotes.isNotEmpty &&
              !state.downloading) ...[
            const SizedBox(height: 6),
            Text(
              state.info!.releaseNotes,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
