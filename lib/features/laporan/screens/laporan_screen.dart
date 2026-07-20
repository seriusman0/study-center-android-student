import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/laporan_provider.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(laporanProvider.notifier).load());
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
      ref.read(laporanProvider.notifier).load(
            from: picked.start.toIso8601String().substring(0, 10),
            to:   picked.end.toIso8601String().substring(0, 10),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laporanProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(laporanProvider.notifier).load()),
        ],
      ),
      body: () {
        if (state.summary == null) {
          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(state.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => ref.read(laporanProvider.notifier).load(), child: const Text('Coba lagi')),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        final summary = state.summary!;
        final matrix  = state.matrix;

        return RefreshIndicator(
          onRefresh: () => ref.read(laporanProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary cards row
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Progres', value: '${summary.pct}%')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Streak', value: '${summary.streak} hari')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Selesai', value: '${summary.checked}/${summary.total}')),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Text('Matriks Harian', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (state.loading) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 8),

              if (matrix != null) ...[
                Text(
                  '${matrix.from} s/d ${matrix.to}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _MatrixTable(matrix.headers, matrix.rows),
                ),
              ] else
                const Text('Pilih rentang tanggal untuk melihat matriks.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _MatrixTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const _MatrixTable(this.headers, this.rows);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        TableRow(
          decoration: BoxDecoration(color: theme.colorScheme.primary.withAlpha(20)),
          children: headers.map((h) => _cell(h, isHeader: true, theme: theme)).toList(),
        ),
        ...rows.map((row) => TableRow(
              children: row.map((cell) {
                final isY = cell == 'Y';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Center(
                    child: isY
                        ? const Icon(Icons.check, color: Colors.green, size: 16)
                        : Text(cell, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _cell(String text, {bool isHeader = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: isHeader
            ? theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)
            : theme.textTheme.bodySmall,
      ),
    );
  }
}
