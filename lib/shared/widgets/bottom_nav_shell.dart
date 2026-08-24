import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/models/user_model.dart';

/// Describes one tab of the bottom nav — icon/label plus the branch route
/// path it maps to. Built dynamically per role so each role only sees tabs
/// backed by API endpoints they're actually authorized to call.
class NavTab {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavTab({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Per-role tab sets. Every role gets Beranda + Profil; the middle tabs
/// differ based on which backend endpoints that role's token can call
/// (see routes/api.php `role:` middleware groups).
List<NavTab> navTabsForRole(UserModel? user) {
  if (user == null) return _studentTabs;

  if (user.isAdmin) return _adminTabs;
  if (user.isMentor) return _mentorTabs;
  // fulltimer/guest/scholarship_teenager/college: no dedicated tools tab
  // yet (Fase 3/4) — Beranda (shared blog+galeri feed) + Profil only.
  if (user.isStudent) return _studentTabs;
  return _minimalTabs;
}

const _studentTabs = [
  NavTab(path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
  NavTab(path: '/jurnal', icon: Icons.book_outlined, activeIcon: Icons.book, label: 'Jurnal'),
  NavTab(path: '/laporan', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Laporan'),
  NavTab(path: '/profil', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
];

const _mentorTabs = [
  NavTab(path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
  NavTab(path: '/mentor/kelas', icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Kelas'),
  NavTab(path: '/mentor/presensi', icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check, label: 'Presensi'),
  NavTab(path: '/profil', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
];

const _adminTabs = [
  NavTab(path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
  NavTab(path: '/admin/dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
  NavTab(path: '/admin/users', icon: Icons.people_outline, activeIcon: Icons.people, label: 'Pengguna'),
  NavTab(path: '/profil', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
];

const _minimalTabs = [
  NavTab(path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
  NavTab(path: '/profil', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
];

class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  final List<NavTab> tabs;
  final int visibleIndex;
  final ValueChanged<int> onTabTap;

  const BottomNavShell({
    super.key,
    required this.shell,
    required this.tabs,
    required this.visibleIndex,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: visibleIndex,
        onTap: onTabTap,
        items: tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
