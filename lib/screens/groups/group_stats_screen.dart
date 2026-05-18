import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_stats_provider.dart';
import '../../widgets/neo_container.dart';
import '../../widgets/glass_container.dart';

class GroupStatsScreen extends ConsumerStatefulWidget {
  const GroupStatsScreen({super.key});

  @override
  ConsumerState<GroupStatsScreen> createState() => _GroupStatsScreenState();
}

class _GroupStatsScreenState extends ConsumerState<GroupStatsScreen> {
  final List<Color> _chartColors = [
    const Color(0xFF5E5CE6), // Indigo
    const Color(0xFF32D74B), // Mint
    const Color(0xFFFF9F0A), // Orange
    const Color(0xFFFF375F), // Pink
    const Color(0xFF64D2FF), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(groupStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Neomorphic background
      appBar: AppBar(
        title: const Text('Shared Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(groupStatsProvider.notifier).fetchStats(),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err', style: const TextStyle(color: Colors.white))),
        data: (data) {
          final stats = data.stats;
          final debts = data.debts;

          if (stats.isEmpty) {
            return const Center(child: Text('В группе пока нет расходов', style: TextStyle(color: Colors.white)));
          }

          final total = stats.fold<double>(0, (sum, item) => sum + item.total);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 20),
                NeoContainer(
                  child: Column(
                    children: [
                      const Text(
                        'Total Group Spend',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${total.toStringAsFixed(0)} ₸',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 60,
                            sections: stats.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final stat = entry.value;
                              return PieChartSectionData(
                                color: _chartColors[idx % _chartColors.length],
                                value: stat.total,
                                title: total > 0
                                    ? '${(stat.total / total * 100).toStringAsFixed(0)}%'
                                    : '0%',
                                radius: 40,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLegend(stats),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Who owes whom',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 20),
                if (debts.isEmpty)
                  const GlassContainer(
                    child: Center(
                      child: Text('All settled up!', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                else
                  ...debts.map((debt) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassContainer(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF375F).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_upward, color: Color(0xFFFF375F)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${debt.from} owes ${debt.to}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${debt.amount.toStringAsFixed(0)} ₸',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  )),
                const SizedBox(height: 30),
                const Text(
                  'Rankings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 20),
                _buildRankingList(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(List<GroupSpend> stats) {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: stats.asMap().entries.map((entry) {
        final idx = entry.key;
        final data = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _chartColors[idx % _chartColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(data.name, style: const TextStyle(color: Colors.white70)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRankingList(List<GroupSpend> stats) {
    final sortedData = [...stats]..sort((a, b) => b.total.compareTo(a.total));

    return Column(
      children: sortedData.map((data) {
        final idx = stats.indexOf(data);
        final color = _chartColors[idx % _chartColors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: NeoContainer(
            padding: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Text('${sortedData.indexOf(data) + 1}',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(data.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
                Text(
                  '${data.total.toStringAsFixed(0)} ₸',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

