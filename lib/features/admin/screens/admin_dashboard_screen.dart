import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_dashboard_provider.dart';

const _roleLabels = {
  'admin': 'Admin',
  'fulltimer': 'Fulltimer',
  'mentor': 'Mentor',
  'student': 'Siswa',
  'guest': 'Tamu',
  'scholarship_teenager': 'Beasiswa Remaja',
  'college': 'Mahasiswa',
};

const _roleColors = {
  'admin': Color(0xFFDC2626),
  'fulltimer': Color(0xFF0891B2),
  'mentor': Color(0xFF7C3AED),
  'student': Color(0xFF059669),
  'guest': Color(0xFF6B7280),
  'scholarship_teenager': Color(0xFFD97706),
  'college': Color(0xFF2563EB),
};

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminDashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminDashboardProvider.notifier).load(),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text('Gagal memuat: ${state.error}',
                            style: TextStyle(color: Colors.red[400])),
                      ),
                    ],
                  )
                : state.stats == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Quick access to Jurnal Monitor — headline feature.
                          Card(
                            color: theme.colorScheme.primary,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.push('/admin/jurnal-monitor'),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    const Icon(Icons.fact_check, color: Colors.white, size: 28),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Monitor Jurnal',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16)),
                                          const SizedBox(height: 2),
                                          Text('Pantau pengisian jurnal semua role',
                                              style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Top-level totals
                          Row(
                            children: [
                              Expanded(
                                  child: _StatCard(
                                      icon: Icons.people,
                                      label: 'Total Pengguna',
                                      value: state.stats!.totalUsers.toString())),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _StatCard(
                                      icon: Icons.article,
                                      label: 'Total Blog',
                                      value: state.stats!.totalBlogs.toString())),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _StatCard(
                                      icon: Icons.comment,
                                      label: 'Komentar',
                                      value: state.stats!.totalComments.toString())),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _AdminFeatureGrid(),
                          const SizedBox(height: 20),

                          Text('Pengguna per Role',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          ...state.stats!.usersByRole.map((entry) => _RoleBar(
                                role: entry.key,
                                count: entry.value,
                                maxCount: state.stats!.usersByRole
                                    .map((e) => e.value)
                                    .fold(0, (a, b) => a > b ? a : b),
                              )),
                        ],
                      ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _RoleBar extends StatelessWidget {
  final String role;
  final int count;
  final int maxCount;

  const _RoleBar({required this.role, required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final color = _roleColors[role] ?? Colors.grey;
    final ratio = maxCount > 0 ? count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(_roleLabels[role] ?? role, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 16,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(count.toString(),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AdminFeatureGrid extends StatelessWidget {
  const _AdminFeatureGrid();

  static final _features = [
    ['Jurnal Life Items', '/admin/jurnal-life-items', Icons.menu_book],
    ['Bible Schedule', '/admin/jurnal-bible-schedule', Icons.menu_book],
    ['Weekly Verse', '/admin/jurnal-weekly-verse', Icons.book],
    ['Role & Permission', '/admin/roles-permissions', Icons.admin_panel_settings],
    ['Mata Pelajaran', '/admin/mata-pelajaran', Icons.subject],
    ['Moderasi Blog', '/admin/blog-moderation', Icons.comment],
    ['Sertifikat', '/admin/certificates', Icons.work_history],
    ['Validasi Pendaftaran', '/admin/pendaftaran', Icons.app_registration],
    ['Name Tags', '/admin/nametags', Icons.badge],
    ['Presensi Mentor', '/admin/mentor-presensi', Icons.assignment],
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.95,
      ),
      itemCount: _features.length,
      itemBuilder: (context, i) {
        final f = _features[i];
        return Card(
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => GoRouter.of(context).push(f[1] as String),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(f[2] as IconData, color: Theme.of(context).colorScheme.primary, size: 22),
                  const SizedBox(height: 4),
                  Text(f[0] as String, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
