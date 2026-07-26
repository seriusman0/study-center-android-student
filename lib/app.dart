import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/journal/screens/journal_screen.dart';
import 'features/journal/screens/journal_history_screen.dart';
import 'features/laporan/screens/laporan_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/profile_edit_screen.dart';
import 'features/blog/screens/blog_detail_screen.dart';
import 'features/blog/screens/blog_create_screen.dart';
import 'features/galeri/screens/galeri_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/bottom_nav_shell.dart';

final _rootKey  = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn  = authState.isAuthenticated;
      final loc         = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Full-screen routes (above the shell) ────────────────────────────
      GoRoute(
        path: '/blog/create',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const BlogCreateScreen(),
      ),
      GoRoute(
        path: '/blog/:slug',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            BlogDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/galeri',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const GaleriScreen(),
      ),
      GoRoute(
        path: '/journal/history',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const JournalHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ProfileEditScreen(),
      ),

      // ── Shell with bottom nav ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, shell) => BottomNavShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home',    builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/jurnal',  builder: (_, __) => const JournalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/laporan', builder: (_, __) => const LaporanScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profil',  builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});

class ScStudentApp extends ConsumerWidget {
  const ScStudentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SC Student',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
