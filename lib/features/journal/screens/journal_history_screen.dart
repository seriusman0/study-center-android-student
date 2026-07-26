import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
class JournalHistoryEntry {
  final String date;
  final int checked;
  final int total;
  final double pct;

  const JournalHistoryEntry({
    required this.date,
    required this.checked,
    required this.total,
    required this.pct,
  });

  factory JournalHistoryEntry.fromJson(Map<String, dynamic> j) =>
      JournalHistoryEntry(
        date:    j['date'] as String? ?? '',
        checked: (j['checked'] as num?)?.toInt() ?? 0,
        total:   (j['total'] as num?)?.toInt() ?? 0,
        pct:     (j['pct'] as num?)?.toDouble() ?? 0.0,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
class _HistoryState {
  final List<JournalHistoryEntry> items;
  final bool loading;
  final String? error;
  final String? from;
  final String? to;

  const _HistoryState({
    this.items = const [],
    this.loading = false,
    this.error,
    this.from,
    this.to,
  });

  _HistoryState copyWith({
    List<JournalHistoryEntry>? items,
    bool? loading,
    String? error,
    String? from,
    String? to,
  }) =>
      _HistoryState(
        items:   items   ?? this.items,
        loading: loading ?? this.loading,
        error:   error,
        from:    from    ?? this.from,
        to:      to      ?? this.to,
      );
}

class _HistoryNotifier extends AutoDisposeNotifier<_HistoryState> {
  @override
  _HistoryState build() {
    Future.microtask(load);
    return const _HistoryState(loading: true);
  }

  Future<void> load({String? from, String? to}) async {
    state = state.copyWith(loading: true, error: null, from: from, to: to);
    try {
      final dio = ref.read(dioProvider);
      final queryParams = <String, dynamic>{};
      final resolvedFrom = from ?? state.from;
      final resolvedTo = to ?? state.to;
      if (resolvedFrom != null) queryParams['from'] = resolvedFrom;
      if (resolvedTo != null) queryParams['to'] = resolvedTo;

      final res = await dio.get(
        ApiConstants.jurnalHistory,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final raw = res.data;
      List<dynamic> list;
      if (raw is Map && raw['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }
      final items = list
          .map((e) => JournalHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = _HistoryState(
        items: items,
        from: resolvedFrom,
        to: resolvedTo,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: extractErrorMessage(e));
    }
  }
}

final _historyProvider =
    NotifierProvider.autoDispose<_HistoryNotifier, _HistoryState>(
        _HistoryNotifier.new);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class JournalHistoryScreen extends ConsumerStatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  ConsumerState<JournalHistoryScreen> createState() =>
      _JournalHistoryScreenState();
}

class _JournalHistoryScreenState
    extends ConsumerState<JournalHistoryScreen> {
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _range ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null && mounted) {
      setState(() => _range = picked);
      final from = picked.start.toIso8601String().substring(0, 10);
      final to   = picked.end.toIso8601String().substring(0, 10);
      ref.read(_historyProvider.notifier).load(from: from, to: to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_historyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Jurnal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter Tanggal',
            onPressed: _pickRange,
          ),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(_historyProvider.notifier).load(),
            ),
        ],
      ),
      body: () {
        if (state.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(_historyProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ]),
            ),
          );
        }
        if (state.items.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Belum ada riwayat jurnal.',
                  style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: const Text('Pilih Rentang Tanggal'),
              ),
            ]),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(_historyProvider.notifier).load(),
          child: Column(
            children: [
              if (state.from != null || state.to != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${_fmtShort(state.from)} – ${_fmtShort(state.to)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() => _range = null);
                          ref.read(_historyProvider.notifier).load();
                        },
                        child: Text('Reset',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[500])),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) =>
                      _HistoryTile(entry: state.items[i], theme: theme),
                ),
              ),
            ],
          ),
        );
      }(),
    );
  }

  String _fmtShort(String? raw) {
    if (raw == null) return '-';
    try {
      return DateFormat('d MMM yyyy', 'id').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _HistoryTile extends StatelessWidget {
  final JournalHistoryEntry entry;
  final ThemeData theme;

  const _HistoryTile({required this.entry, required this.theme});

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(entry.date);
    final pct = entry.pct.clamp(0.0, 100.0) / 100;
    final isComplete = entry.pct >= 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: isComplete ? Colors.green : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${entry.checked}/${entry.total}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? Colors.green : theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.pct.toStringAsFixed(0)}% selesai',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('EEEE, d MMMM yyyy', 'id').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
