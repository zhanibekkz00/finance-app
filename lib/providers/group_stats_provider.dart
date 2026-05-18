import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class GroupSpend {
  final String name;
  final double total;

  GroupSpend({required this.name, required this.total});
}

class Debt {
  final String from;
  final String to;
  final double amount;

  Debt({required this.from, required this.to, required this.amount});
}

class GroupStatsData {
  final List<GroupSpend> stats;
  final List<Debt> debts;

  GroupStatsData({required this.stats, required this.debts});
}

class GroupStatsNotifier extends StateNotifier<AsyncValue<GroupStatsData>> {
  final ApiService _apiService = ApiService();

  GroupStatsNotifier() : super(const AsyncValue.loading()) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.get('/groups/stats');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final stats = data.map((item) {
          double totalVal = 0.0;
          final rawTotal = item['total'];
          if (rawTotal is num) {
            totalVal = rawTotal.toDouble();
          } else if (rawTotal is String) {
            totalVal = double.tryParse(rawTotal) ?? 0.0;
          }
          
          return GroupSpend(
            name: item['name'] ?? 'Unknown',
            total: totalVal,
          );
        }).toList();

        final debts = _calculateDebts(stats);

        state = AsyncValue.data(GroupStatsData(stats: stats, debts: debts));
      } else {
        state = AsyncValue.error('Failed to load stats', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Debt> _calculateDebts(List<GroupSpend> stats) {
    if (stats.isEmpty) return [];

    final totalSpent = stats.fold<double>(0, (sum, item) => sum + item.total);
    final average = totalSpent / stats.length;

    List<Map<String, dynamic>> balances = stats.map((s) {
      return {'name': s.name, 'balance': s.total - average};
    }).toList();

    balances.sort((a, b) => a['balance'].compareTo(b['balance']));

    int i = 0;
    int j = balances.length - 1;
    List<Debt> debts = [];

    while (i < j) {
      double owe = balances[i]['balance'];
      double owed = balances[j]['balance'];

      if (owe >= -0.01) {
        i++;
        continue;
      }
      if (owed <= 0.01) {
        j--;
        continue;
      }

      double amount = (-owe < owed) ? -owe : owed;
      debts.add(Debt(from: balances[i]['name'], to: balances[j]['name'], amount: amount));

      balances[i]['balance'] += amount;
      balances[j]['balance'] -= amount;

      if (balances[i]['balance'] >= -0.01) i++;
      if (balances[j]['balance'] <= 0.01) j--;
    }

    return debts;
  }
}

final groupStatsProvider = StateNotifierProvider<GroupStatsNotifier, AsyncValue<GroupStatsData>>((ref) {
  return GroupStatsNotifier();
});
