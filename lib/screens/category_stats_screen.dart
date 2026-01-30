import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:finance_app/l10n/generated/app_localizations.dart';

class CategoryStatsScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryStatsScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final category =
        ref.read(categoryProvider.notifier).getCategoryById(categoryId);
    final stats =
        ref.read(transactionProvider.notifier).getCategoryStats(categoryId);

    final transactions = stats['transactions'] as List<TransactionModel>? ?? [];
    final totalSpent = stats['totalSpent'] as double;
    final totalEarned = stats['totalEarned'] as double;
    final count = stats['count'] as int;
    final average = stats['average'] as double;

    // Calculate monthly stats
    final monthlyStats = <String, double>{};
    for (var tx in transactions) {
      final monthKey = DateFormat('MMM yyyy').format(tx.date);
      monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + tx.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryStats),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (category != null)
                      CircleAvatar(
                        backgroundColor: Color(category.colorValue),
                        radius: 30,
                        child: Icon(
                          IconData(category.iconCode,
                              fontFamily: 'MaterialIcons'),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category?.name ?? 'Unknown',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${l10n.transactionCount}: $count',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Summary Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    _buildStatRow(l10n.totalSpent, totalSpent, Colors.red),
                    _buildStatRow(l10n.totalEarned, totalEarned, Colors.green),
                    _buildStatRow(l10n.averageAmount, average, Colors.blue),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Monthly Stats
            if (monthlyStats.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.monthlyStats,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      ...monthlyStats.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key),
                              Text(
                                entry.value.toStringAsFixed(2),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Recent Transactions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.transactions,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    ...transactions.take(10).map((tx) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tx.note.isEmpty ? 'No note' : tx.note),
                        subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                        trailing: Text(
                          '${tx.type == TransactionType.income ? '+' : '-'}${tx.amount} ${tx.currency}',
                          style: TextStyle(
                            color: tx.type == TransactionType.income
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
