import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/jurnal_monitor_model.dart';
import '../providers/jurnal_monitor_provider.dart';
import 'jurnal_monitor_detail_screen.dart';

const _roles = ['student', 'college', 'scholarship_teenager'];
const _roleLabels = {
  'student': 'Siswa',
  'college': 'Mahasiswa',
  'scholarship_teenager': 'Beasiswa Remaja',
};

/// Admin screen: monitor jurnal fill status across ALL roles that
/// keep a jurnal (student, college, scholarship_teenager) in one place.
/// Top section shows a cross-role summary (today/week completion %),
/// tabs below let the admin drill into each role's user list, tap a
/// user to see their full checklist matrix.
class JurnalMonitorScreen extends ConsumerStatefulWidget {
  const JurnalMonitorScreen({super.key});

  @override
  ConsumerState<JurnalMonitorScreen> createState() => _JurnalMonitorScreenState();
}

class _JurnalMonitorScreenState extends ConsumerState<JurnalMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
    Future.microtask(() {
      ref.read(jurnalMonitorSummaryProvider.notifier).load();
      for (final role in _roles) {
        ref.read(jurnalMonitorListProvider(role).notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Jurnal'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _roles.map((r) => Tab(text: _roleLabels[r])).toList(),
        ),
      ),
      body: Column(
        children: [
          const _SummaryHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _roles.map((role) => _RoleUserList(role: role)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends ConsumerWidget {
  const _SummaryHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jurnalMonitorSummaryProvider);
    final theme = Theme.of(context);

    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Gagal memuat ringkasan: ${state.error}',
            style: TextStyle(color: Colors.red[400], fontSize: 13)),
      );
    }
    final summary = state.summary;
    if (summary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.primary.withValues(alpha: 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Pengisian Jurnal Minggu Ini',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: _roles.map((role) {
              final r = summary.byRole[role];
              return Expanded(
                child: _RoleSummaryCard(
                  label: _roleLabels[role] ?? role,
                  totalUsers: r?.totalUsers ?? 0,
                  activeWeek: r?.activeWeek ?? 0,
                  pctWeek: r?.pctWeek ?? 0,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoleSummaryCard extends StatelessWidget {
  final String label;
  final int totalUsers;
  final int activeWeek;
  final double pctWeek;

  const _RoleSummaryCard({
    required this.label,
    required this.totalUsers,
    required this.activeWeek,
    required this.pctWeek,
  });

  Color get _color {
    if (pctWeek >= 70) return Colors.green;
    if (pctWeek >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${pctWeek.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _color)),
          Text('$activeWeek/$totalUsers aktif',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _RoleUserList extends ConsumerStatefulWidget {
  final String role;
  const _RoleUserList({required this.role});

  @override
  ConsumerState<_RoleUserList> createState() => _RoleUserListState();
}

class _RoleUserListState extends ConsumerState<_RoleUserList>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(jurnalMonitorListProvider(widget.role));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari nama/username...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (v) => ref
                .read(jurnalMonitorListProvider(widget.role).notifier)
                .load(query: v),
          ),
        ),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : state.error != null
                  ? Center(
                      child: Text('Gagal memuat: ${state.error}',
                          style: TextStyle(color: Colors.red[400])))
                  : state.users.isEmpty
                      ? const Center(
                          child: Text('Tidak ada pengguna', style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(jurnalMonitorListProvider(widget.role).notifier)
                              .load(query: _searchCtrl.text),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: state.users.length,
                            itemBuilder: (context, i) =>
                                _UserJurnalTile(user: state.users[i], role: widget.role),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _UserJurnalTile extends StatelessWidget {
  final JurnalMonitorUser user;
  final String role;

  const _UserJurnalTile({required this.user, required this.role});

  String _formatLastDate(String? raw) {
    if (raw == null) return 'Belum pernah mengisi';
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(dt.year, dt.month, dt.day))
          .inDays;
      if (diff == 0) return 'Hari ini';
      if (diff == 1) return 'Kemarin';
      return DateFormat('d MMM yyyy', 'id').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor() {
    if (user.lastJurnalDate == null) return Colors.grey;
    try {
      final dt = DateTime.parse(user.lastJurnalDate!);
      final now = DateTime.now();
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(dt.year, dt.month, dt.day))
          .inDays;
      if (diff <= 1) return Colors.green;
      if (diff <= 3) return Colors.orange;
      return Colors.red;
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
        child: user.avatar == null
            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_formatLastDate(user.lastJurnalDate)} • ${user.checksLast7Days}x minggu ini'
              '${user.cabangNama != null ? " • ${user.cabangNama}" : ""}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => JurnalMonitorDetailScreen(role: role, userId: user.id, userName: user.name),
        ));
      },
    );
  }
}
