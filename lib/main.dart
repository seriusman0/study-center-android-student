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
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] stack: ${details.stack?.toString().split('\n').take(5).join('\n')}');
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

  @override
  void initState() {
    super.initState();
    _init();
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
    // Listen for network restore to trigger journal sync — must be in build().
    ref.listen<bool>(
      connectivityProvider.select((s) => s.valueOrNull ?? false),
      (prev, online) {
        if (online) {
          debugPrint('[AppInit] Network restored — triggering journal sync');
          ref.invalidate(journalSyncSignalProvider);
        }
      },
    );
    return const ScStudentApp();
  }
}
