import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/app_update_service.dart';
import 'core/services/offline_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/providers/journal_sync_signal.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture every Flutter framework error so we get the FULL stack trace
  // (the per-screen _JournalErrorBoundary overwrites this handler when
  // mounted — so we must log BEFORE any handler swap can hide the root cause).
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('══════ [FlutterError] ══════');
    debugPrint('[FlutterError] exception: ${details.exceptionAsString()}');
    debugPrint('[FlutterError] library:   ${details.library}');
    debugPrint('[FlutterError] context:   ${details.context}');
    if (details.informationCollector != null) {
      try {
        details.informationCollector!();
      } catch (_) {}
    }
    final stackStr = details.stack?.toString() ?? 'no stack';
    final firstFrames = stackStr.split('\n').take(100).join('\n');
    debugPrint('[FlutterError] stack (first 100 frames):');
    debugPrint(firstFrames);
    debugPrint('══════ [/FlutterError] ══════');
    // Also forward to previous handler so the UI still shows the error.
    previousOnError?.call(details);
  };
  await initializeDateFormatting('id', null);

  runApp(
    ProviderScope(
      overrides: [
        offlineServiceProvider.overrideWithValue(OfflineService()),
      ],
      child: _AppInit(),
    ),
  );
}

class _AppInit extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppInit> createState() => _AppInitState();
}

class _AppInitState extends ConsumerState<_AppInit> {
  bool _ready = false;
  ProviderSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _init();
    // Pindahkan ref.listen ke initState() menggunakan listenManual agar
    // tidak pernah dipanggil di dalam frame build — pola di build() menyebabkan
    // ref.invalidate() ter-fire saat MouseTracker sedang update device,
    // sehingga assertion '_debugDuringDeviceUpdate is not true' muncul
    // berulang-ulang di layar Jurnal dan layar lainnya.
    _connectivitySub = ref.listenManual<bool>(
      connectivityProvider.select((s) => s.valueOrNull ?? false),
      (prev, online) {
        if (online) {
          debugPrint('[AppInit] Network restored — triggering journal sync');
          // Gunakan addPostFrameCallback agar invalidate tidak terjadi
          // di tengah frame yang sedang berjalan.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ref.invalidate(journalSyncSignalProvider);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySub?.close();
    super.dispose();
  }

  Future<void> _init() async {
    // Attempt offline session restore before showing the app.
    await ref.read(authProvider.notifier).restoreSession();
    if (mounted) setState(() => _ready = true);

    // Background version check — non-blocking, after UI is ready.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(appUpdateProvider.notifier).checkForUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }
    return const ScStudentApp();
  }
}
