import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/models/user_model.dart';
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
import 'features/mentor/screens/mentor_kelas_screen.dart';
import 'features/mentor/screens/mentor_presensi_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_users_screen.dart';
import 'features/admin/screens/jurnal_life_items_screen.dart';
import 'features/admin/screens/jurnal_bible_schedule_screen.dart';
import 'features/admin/screens/jurnal_weekly_verse_screen.dart';
import 'features/admin/screens/roles_permissions_screen.dart';
import 'features/admin/screens/mata_pelajaran_screen.dart';
import 'features/admin/screens/blog_moderation_screen.dart';
import 'features/admin/screens/certificates_screen.dart';
import 'features/admin/screens/pendaftaran_screen.dart';
import 'features/admin/screens/nametags_screen.dart';
import 'features/admin/screens/mentor_presensi_admin_screen.dart';
import 'features/admin/screens/jurnal_monitor_screen.dart';
import 'features/admin/screens/jurnal_offline_screen.dart';
import 'features/admin/screens/admin_notifications_screen.dart';
import 'features/admin/screens/college_jurnal_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/bottom_nav_shell.dart';

final _rootKey  = GlobalKey<NavigatorState>();

/// All tab paths that exist ANYWHERE across roles, in a fixed order that
/// matches the branch list below. StatefulShellRoute needs a static branch
/// list at build time, so every role-specific tab is always present as a
/// branch — BottomNavShell just hides/reorders which ones are *visible*
/// per role (see navTabsForRole). The redirect guard below still blocks
/// direct navigation into another role's branch.
const _allTabPaths = [
  '/home',           // 0 — everyone
  '/jurnal',         // 1 — student
  '/laporan',        // 2 — student
  '/mentor/kelas',    // 3 — mentor/admin
  '/mentor/presensi', // 4 — mentor/admin
  '/admin/dashboard', // 5 — admin
  '/admin/users',     // 6 — admin
  '/profil',          // 7 — everyone
];

bool _canAccessTab(UserModel? user, String path) {
  if (user == null) return path == '/home' || path == '/profil';
  switch (path) {
    case '/jurnal':
    case '/laporan':
      return user.isStudent;
    case '/mentor/kelas':
    case '/mentor/presensi':
      return user.hasMentorTools;
    case '/admin/dashboard':
    case '/admin/users':
      return user.isAdmin;
    default:
      return true; // /home, /profil
  }
}

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

      // Block direct navigation (deep link, back-stack, etc.) into a tab
      // this role doesn't have — bounce to /home rather than showing a
      // screen wired to an API the backend will 403 anyway.
      if (isLoggedIn && _allTabPaths.contains(loc)) {
        final user = authState.user;
        if (!_canAccessTab(user, loc)) return '/home';
      }
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
      GoRoute(
        path: '/admin/jurnal-monitor',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const JurnalMonitorScreen(),
      ),
      GoRoute(
        path: '/admin/jurnal-life-items',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const JurnalLifeItemsScreen(),
      ),
      GoRoute(
        path: '/admin/jurnal-bible-schedule',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const JurnalBibleScheduleScreen(),
      ),
      GoRoute(
        path: '/admin/jurnal-weekly-verse',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const JurnalWeeklyVerseScreen(),
      ),
      GoRoute(
        path: '/admin/roles-permissions',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RolesPermissionsScreen(),
      ),
      GoRoute(
        path: '/admin/mata-pelajaran',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MataPelajaranScreen(),
      ),
      GoRoute(
        path: '/admin/blog-moderation',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const BlogModerationScreen(),
      ),
      GoRoute(
        path: '/admin/certificates',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/admin/pendaftaran',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const PendaftaranScreen(),
      ),
      GoRoute(
        path: '/admin/nametags',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NameTagsScreen(),
      ),
      GoRoute(
        path: '/admin/mentor-presensi',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MentorPresensiAdminScreen(),
      ),
      GoRoute(
        path: '/admin/jurnal-offline',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const JurnalOfflineScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/jurnal-college',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CollegeJurnalScreen(),
      ),

      // ── Shell with bottom nav ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, shell) => _RoleAwareShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/jurnal', builder: (_, __) => const JournalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/laporan', builder: (_, __) => const LaporanScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/mentor/kelas', builder: (_, __) => const MentorKelasScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/mentor/presensi', builder: (_, __) => const MentorPresensiScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profil', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Wraps BottomNavShell but only exposes the branch indices this user's
/// role actually has a visible tab for (see navTabsForRole). Tapping a tab
/// maps the visible-tab index back to its real branch index in the
/// underlying StatefulNavigationShell.
class _RoleAwareShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const _RoleAwareShell({required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final tabs = navTabsForRole(user);
    final branchIndices = tabs.map((t) => _allTabPaths.indexOf(t.path)).toList();

    // Map the shell's real currentIndex to this role's visible-tab index.
    final visibleIndex = branchIndices.indexOf(shell.currentIndex);

    return BottomNavShell(
      shell: shell,
      tabs: tabs,
      visibleIndex: visibleIndex < 0 ? 0 : visibleIndex,
      onTabTap: (visibleIdx) {
        final realBranchIndex = branchIndices[visibleIdx];
        shell.goBranch(realBranchIndex,
            initialLocation: realBranchIndex == shell.currentIndex);
      },
    );
  }
}

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
