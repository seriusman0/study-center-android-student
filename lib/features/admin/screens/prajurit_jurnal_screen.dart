import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prajurit_jurnal_model.dart';
import '../providers/prajurit_jurnal_provider.dart';
import '../../../shared/theme/design_tokens.dart';

/// Admin screen for Jurnal prajurit monitoring:
/// Tab 1 — Dashboard (list mahasiswa + progress mingguan)
/// Tab 2 — Bible Reading items
/// Tab 3 — prajurit Curriculum items
class PrajuritJurnalScreen extends ConsumerStatefulWidget {
  const PrajuritJurnalScreen({super.key});
  @override
  ConsumerState<PrajuritJurnalScreen> createState() => _PrajuritJurnalScreenState();
}

class _PrajuritJurnalScreenState extends ConsumerState<PrajuritJurnalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(PrajuritDashboardProvider.notifier).load();
      ref.read(PrajuritBibleProvider.notifier).load();
      ref.read(PrajuritItemsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Mahasiswa'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Bible'),
            Tab(text: 'Kurikulum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _DashboardTab(),
          _BibleTab(),
          _ItemsTab(),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(PrajuritDashboardProvider);
    if (state.loading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.users.isEmpty) {
      return Center(child: Text('Error: ${state.error}'));
    }
    if (state.users.isEmpty) {
      return const Center(child: Text('Tidak ada data mahasiswa'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(PrajuritDashboardProvider.notifier).load(),
      child: ListView.separated(
        itemCount: state.users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final u = state.users[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  u.activeToday ? AppColors.success : AppColors.border,
              child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: u.activeToday ? Colors.white : AppColors.textMuted)),
            ),
            title: Text(u.name),
            subtitle: Text(u.email,
                style: const TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${u.pctWeek.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            u.pctWeek >= 70 ? Colors.green : Colors.orange)),
                Text('minggu ini',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Bible Tab ─────────────────────────────────────────────────────────────────

class _BibleTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(PrajuritBibleProvider);
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(child: Text('Error: ${state.error}'));
    }
    if (state.items.isEmpty) {
      return const Center(child: Text('Belum ada jadwal Bible'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(PrajuritBibleProvider.notifier).load(),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final item = state.items[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
              child: Text('${item.dayNo}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
            ),
            title: Text(item.title),
            subtitle: Text(item.passage,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          );
        },
      ),
    );
  }
}

// ── prajurit Items Tab ─────────────────────────────────────────────────────────

class _ItemsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(PrajuritItemsProvider);
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(child: Text('Error: ${state.error}'));
    }
    if (state.items.isEmpty) {
      return const Center(child: Text('Belum ada item kurikulum'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(PrajuritItemsProvider.notifier).load(),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final item = state.items[i];
          return ListTile(
            leading: Icon(
              item.isActive ? Icons.check_circle : Icons.circle_outlined,
              color: item.isActive ? AppColors.success : AppColors.textMuted,
            ),
            title: Text(item.name),
            subtitle: item.description != null
                ? Text(item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12))
                : null,
          );
        },
      ),
    );
  }
}
