import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/college_jurnal_model.dart';
import '../providers/college_jurnal_provider.dart';

/// Admin screen for Jurnal College monitoring:
/// Tab 1 — Dashboard (list mahasiswa + progress mingguan)
/// Tab 2 — Bible Reading items
/// Tab 3 — College Curriculum items
class CollegeJurnalScreen extends ConsumerStatefulWidget {
  const CollegeJurnalScreen({super.key});
  @override
  ConsumerState<CollegeJurnalScreen> createState() => _CollegeJurnalScreenState();
}

class _CollegeJurnalScreenState extends ConsumerState<CollegeJurnalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(collegeDashboardProvider.notifier).load();
      ref.read(collegeBibleProvider.notifier).load();
      ref.read(collegeItemsProvider.notifier).load();
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
    final state = ref.watch(collegeDashboardProvider);
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
      onRefresh: () => ref.read(collegeDashboardProvider.notifier).load(),
      child: ListView.separated(
        itemCount: state.users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final u = state.users[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  u.activeToday ? Colors.green : Colors.grey.shade300,
              child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: u.activeToday ? Colors.white : Colors.grey)),
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
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
    final state = ref.watch(collegeBibleProvider);
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
      onRefresh: () => ref.read(collegeBibleProvider.notifier).load(),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          );
        },
      ),
    );
  }
}

// ── College Items Tab ─────────────────────────────────────────────────────────

class _ItemsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collegeItemsProvider);
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
      onRefresh: () => ref.read(collegeItemsProvider.notifier).load(),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final item = state.items[i];
          return ListTile(
            leading: Icon(
              item.isActive ? Icons.check_circle : Icons.circle_outlined,
              color: item.isActive ? Colors.green : Colors.grey,
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
