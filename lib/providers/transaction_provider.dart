import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/group_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? type;
  final String? categoryId;

  TransactionFilter({this.startDate, this.endDate, this.type, this.categoryId});

  bool matches(TransactionModel tx) {
    if (type != null && tx.type != type) return false;
    if (categoryId != null && tx.categoryId != categoryId) return false;
    if (startDate != null && tx.date.isBefore(startDate!)) return false;
    if (endDate != null && tx.date.isAfter(endDate!)) return false;
    return true;
  }
}

class TransactionState {
  final List<TransactionModel> transactions;
  final TransactionFilter filter;
  final bool isLoading;
  final String? currentGroupId;

  TransactionState({
    required this.transactions,
    required this.filter,
    this.isLoading = false,
    this.currentGroupId,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    TransactionFilter? filter,
    bool? isLoading,
    String? currentGroupId,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      currentGroupId: currentGroupId ?? this.currentGroupId,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final ApiService _apiService = ApiService();
  final Ref _ref;
  final GroupService _groupService = GroupService();

  TransactionNotifier(this._ref)
      : super(TransactionState(transactions: [], filter: TransactionFilter())) {
    _init();
  }

  void _init() {
    _ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        fetchTransactions();
      } else {
        state = state.copyWith(transactions: [], currentGroupId: null);
      }
    });

    if (_ref.read(authProvider).status == AuthStatus.authenticated) {
      fetchTransactions();
    }
  }

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true);

    final auth = _ref.read(authProvider);
    if (auth.userId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // 1. Get Group ID
      String? groupId = await _groupService.getUserGroupId(auth.userId!);
      state = state.copyWith(currentGroupId: groupId);

      // 2. Fetch from API
      final response = await _apiService.get('/transactions');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final transactions = data.map((json) {
          try {
            // Robust parsing of amount (handles both String and num from Decimal)
            double parsedAmount = 0.0;
            if (json['amount'] is num) {
              parsedAmount = (json['amount'] as num).toDouble();
            } else if (json['amount'] is String) {
              parsedAmount = double.tryParse(json['amount']) ?? 0.0;
            }

            return TransactionModel(
              id: json['id'],
              type: TransactionType.values.firstWhere((e) => e.name == json['type']),
              amount: parsedAmount,
              categoryId: json['categoryId'] ?? '',
              date: DateTime.parse(json['date']),
              note: json['note'] ?? '',
              isRecurring: json['isRecurring'] ?? false,
              currency: json['currency'] ?? 'USD',
              recurrenceInterval: RecurrenceInterval.values.firstWhere(
                  (e) => e.name == (json['recurrenceInterval'] ?? 'none')),
              nextOccurrence: json['nextOccurrence'] != null
                  ? DateTime.parse(json['nextOccurrence'])
                  : null,
              isPinned: json['isPinned'] ?? false,
              userId: json['userId'],
              groupId: json['groupId'],
            );
          } catch (e) {
            debugPrint('Error parsing transaction ${json['id']}: $e');
            return null;
          }
        }).whereType<TransactionModel>().toList();

        state = state.copyWith(
          transactions: _sort(transactions),
          isLoading: false,
        );
      } else {
        debugPrint('Failed to fetch transactions: ${response.statusCode}');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  List<TransactionModel> _sort(List<TransactionModel> txs) {
    return [...txs]..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.date.compareTo(a.date);
      });
  }

  Future<void> add(TransactionModel tx) async {
    try {
      final auth = _ref.read(authProvider);
      if (auth.userId == null) {
        debugPrint('Cannot add transaction: Auth is null');
        return;
      }

      final body = {
        'type': tx.type.name,
        'amount': tx.amount,
        'categoryId': tx.categoryId,
        'date': tx.date.toIso8601String(),
        'note': tx.note,
        'currency': tx.currency,
        'isRecurring': tx.isRecurring,
        'recurrenceInterval': tx.recurrenceInterval.name,
        'isPinned': tx.isPinned,
      };
      
      debugPrint('Adding transaction: $body');

      final response = await _apiService.post('/transactions', body);

      if (response.statusCode == 201) {
        debugPrint('Transaction added successfully');
        // Small delay to allow DB processing if needed, though usually instant
        await fetchTransactions();
      } else {
        debugPrint('Error adding transaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception adding transaction: $e');
    }
  }

  Future<void> update(TransactionModel tx) async {
    try {
      final response = await _apiService.put('/transactions/${tx.id}', {
        'type': tx.type.name,
        'amount': tx.amount,
        'categoryId': tx.categoryId,
        'date': tx.date.toIso8601String(),
        'note': tx.note,
        'currency': tx.currency,
        'isRecurring': tx.isRecurring,
        'recurrenceInterval': tx.recurrenceInterval.name,
        'isPinned': tx.isPinned,
      });

      if (response.statusCode == 200) {
        await fetchTransactions();
      } else {
        debugPrint('Error updating transaction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception updating transaction: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final response = await _apiService.delete('/transactions/$id');
      if (response.statusCode == 200) {
        await fetchTransactions();
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $id');
    }
  }

  Future<void> togglePin(String id) async {
    try {
      final response = await _apiService.put('/transactions/$id/pin', {});
      if (response.statusCode == 200) {
        await fetchTransactions();
      }
    } catch (e) {
      debugPrint('Error toggling pin: $e');
    }
  }

  Map<String, dynamic> getCategoryStats(String categoryId) {
    final categoryTxs =
        state.transactions.where((tx) => tx.categoryId == categoryId).toList();

    if (categoryTxs.isEmpty) {
      return {
        'totalSpent': 0.0,
        'totalEarned': 0.0,
        'count': 0,
        'average': 0.0,
      };
    }

    double totalSpent = 0.0;
    double totalEarned = 0.0;

    for (var tx in categoryTxs) {
      if (tx.type == TransactionType.expense) {
        totalSpent += tx.amount;
      } else {
        totalEarned += tx.amount;
      }
    }

    return {
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'count': categoryTxs.length,
      'average': (totalSpent + totalEarned) / categoryTxs.length,
      'transactions': categoryTxs,
    };
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref);
});
