import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/journal/screens/journal_screen.dart';
import 'features/laporan/screens/laporan_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/bottom_nav_shell.dart';

final _routerProvider = Provider((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final onLogin  = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (ctx, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (ctx, _, shell) => BottomNavShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home',    builder: (ctx, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/jurnal',  builder: (ctx, _) => const JournalScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/laporan', builder: (ctx, _) => const LaporanScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (ctx, _) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

class ScStudentApp extends ConsumerWidget {
  const ScStudentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'SC Student',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
