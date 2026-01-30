import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider);
    
    // Logic to calculate pie data
    final Map<String, double> byCat = {};
    for (final tx in txState.transactions.where((e) => e.type == TransactionType.expense)) {
      byCat[tx.categoryId] = (byCat[tx.categoryId] ?? 0) + tx.amount;
    }

    final sections = byCat.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        title: e.key, // Should map ID to Name in real app
        color: Colors.primaries[e.key.hashCode % Colors.primaries.length],
        radius: 50,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Center(
        child: sections.isEmpty
            ? const Text('No expenses to show')
            : PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
      ),
    );
  }
}
