import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../providers/jurnal_monitor_provider.dart';

/// Full checklist matrix for one user — dates (rows) x jurnal items
/// (columns), same data shape as the student "Laporan" screen but for
/// admin drill-down across any role (student/college/scholarship_teenager).
class JurnalMonitorDetailScreen extends ConsumerStatefulWidget {
  final String role;
  final int userId;
  final String userName;

  const JurnalMonitorDetailScreen({
    super.key,
    required this.role,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<JurnalMonitorDetailScreen> createState() => _JurnalMonitorDetailScreenState();
}

class _JurnalMonitorDetailScreenState extends ConsumerState<JurnalMonitorDetailScreen> {
  late final args = JurnalMonitorDetailArgs(widget.role, widget.userId);
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(jurnalMonitorDetailProvider(args).notifier).load());
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final dio = ref.read(dioProvider);
      final dir = await getTemporaryDirectory();
      final safeName = widget.userName.replaceAll(RegExp(r'[^a-zA-Z0-9_ -]'), '');
      final path = '${dir.path}/jurnal-${widget.role}-$safeName.csv';

      final response = await dio.get(
        ApiConstants.jurnalMonitorExport(widget.role, widget.userId),
        options: Options(responseType: ResponseType.bytes),
      );

      final file = await File(path).writeAsBytes(response.data as List<int>);
      if (mounted) {
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor: ${extractErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jurnalMonitorDetailProvider(args));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Jurnal — ${widget.userName}'),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download),
            tooltip: 'Ekspor CSV',
            onPressed: _exporting ? null : _exportCsv,
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Gagal memuat: ${state.error}',
                        style: TextStyle(color: Colors.red[400]), textAlign: TextAlign.center),
                  ),
                )
              : state.detail == null
                  ? const SizedBox.shrink()
                  : _MatrixView(detail: state.detail!, theme: theme),
    );
  }
}

class _MatrixView extends StatelessWidget {
  final dynamic detail; // JurnalMonitorDetail
  final ThemeData theme;

  const _MatrixView({required this.detail, required this.theme});

  @override
  Widget build(BuildContext context) {
    final matrix = detail.matrix;
    final pct = matrix.pct as double;

    Color pctColor() {
      if (pct >= 70) return Colors.green;
      if (pct >= 40) return Colors.orange;
      return Colors.red;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Column(
            children: [
              Text('${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: pctColor())),
              const SizedBox(height: 4),
              Text('${matrix.checked} dari ${matrix.total} item terisi',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text('Periode: ${detail.from} s/d ${detail.to}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                columns: (matrix.headers as List<String>)
                    .map((h) => DataColumn(
                          label: Text(h,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
                rows: (matrix.rows as List<List<String>>)
                    .map((row) => DataRow(
                          cells: row
                              .map((cell) => DataCell(Text(
                                    cell,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cell == 'Y' ? Colors.green[700] : Colors.grey[400],
                                      fontWeight: cell == 'Y' ? FontWeight.w700 : FontWeight.normal,
                                    ),
                                  )))
                              .toList(),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
