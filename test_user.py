import re

file_path = "lib/features/home/screens/home_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

stats_circle = """
class _MentorStatsCircle extends ConsumerWidget {
  const _MentorStatsCircle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorDashboardProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    
    return Column(
      children: [
        Text(
          'Rekap Bulan Ini',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primary.withOpacity(0.9), primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.loading && state.stats.totalKelas == 0)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  Text(
                    '${state.stats.totalKelas}',
                    style: const TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'Kelas',
                    style: TextStyle(
                      fontSize: 14, 
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.stats.totalMurid} Murid Diajar',
                      style: const TextStyle(
                        fontSize: 11, 
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}
"""

if "_MentorStatsCircle extends" not in content:
    content += "\n" + stats_circle
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Added _MentorStatsCircle")
