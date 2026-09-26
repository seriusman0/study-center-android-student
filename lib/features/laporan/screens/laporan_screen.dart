import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/laporan_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../auth/providers/auth_provider.dart';

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Jurnal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(laporanProvider.notifier).load(),
          ),
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final summary = state.summary!;
        final matrix  = state.matrix;

        final roles = user?.roles ?? [];
        final hasMultipleRoles = roles.length > 1;
        
        final roleLabels = const {
          'student': 'Siswa',
          'scholarship_teenager': 'Remaja Beasiswa',
          'college': 'Mahasiswa',
          'prajurit': 'Prajurit',
        };
        final readableRoles = roles.map((r) => roleLabels[r] ?? r).toList();

        return RefreshIndicator(
          onRefresh: () => ref.read(laporanProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Info box matching web
              if (hasMultipleRoles)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade500, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Kamu memiliki '),
                              TextSpan(text: '${roles.length} program jurnal', style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: ' (${readableRoles.join(' + ')}). Progress harian di bawah menggabungkan semua item dari program tersebut.'),
                            ],
                          ),
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasMultipleRoles) const SizedBox(height: 16),

              // Grid matching web
              Row(
                children: [
                  Expanded(
                    child: _WebStatCard(
                      value: '${summary.checked}/${summary.total}',
                      label: 'Total Selesai',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WebStatCard(
                      value: '${summary.pct}%',
                      label: 'Progres',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Harian Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadow.low,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Progress Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (state.loading) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              if (!state.loading) const Text('Gabungan semua program', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Date picker row
                          InkWell(
                            onTap: _pickRange,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.date_range, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    matrix != null ? '${matrix.from}  -  ${matrix.to}' : 'Pilih Tanggal',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    // Accordion List
                    if (matrix != null && matrix.rows.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: matrix.rows.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          // The rows are returned ascending, maybe we should reverse them to show latest first like web?
                          // Web seems to show latest first (e.g., Thu, 24 Sep). Let's reverse.
                          final row = matrix.rows[matrix.rows.length - 1 - index];
                          final dateStr = row[0]; // e.g., "2026-09-24"
                          
                          // Parse date for beautiful formatting
                          DateTime? date;
                          try {
                            date = DateTime.parse(dateStr);
                          } catch (_) {}

                          final displayDate = date != null 
                              ? DateFormat('EEE, dd MMM yyyy').format(date)
                              : dateStr;

                          int yCount = 0;
                          for (int i = 1; i < row.length; i++) {
                            if (row[i] == 'Y') yCount++;
                          }
                          final totalItems = row.length - 1;
                          final pct = totalItems > 0 ? (yCount / totalItems * 100).round() : 0;

                          return ExpansionTile(
                            iconColor: AppColors.textSecondary,
                            collapsedIconColor: AppColors.textSecondary,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayDate,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withAlpha(30),
                                    border: Border.all(color: AppColors.primaryLight.withAlpha(80)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.stars, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text('${yCount * 10} poin', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                              ],
                            ),
                            children: [
                              Container(
                                color: AppColors.background,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  children: List.generate(totalItems, (i) {
                                    final header = matrix.headers[i + 1];
                                    final val = row[i + 1];
                                    final isY = val == 'Y';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isY ? Icons.check_circle : Icons.radio_button_unchecked,
                                            color: isY ? AppColors.success : AppColors.borderStrong,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              header,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isY ? AppColors.textPrimary : AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else if (matrix != null)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Tidak ada data di rentang ini.', style: TextStyle(color: AppColors.textMuted))),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }(),
    );
  }
}

class _WebStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _WebStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.low,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
