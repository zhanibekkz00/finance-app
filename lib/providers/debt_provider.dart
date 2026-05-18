import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

class DebtState {
  final List<DebtModel> debts;
  final bool isLoading;

  DebtState({required this.debts, this.isLoading = false});

  DebtState copyWith({List<DebtModel>? debts, bool? isLoading}) {
    return DebtState(
      debts: debts ?? this.debts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DebtNotifier extends StateNotifier<DebtState> {
  final ApiService _apiService = ApiService();
  final Ref _ref;

  DebtNotifier(this._ref) : super(DebtState(debts: [])) {
    _init();
  }

  void _init() {
    _ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        fetchDebts();
      } else {
        state = state.copyWith(debts: []);
      }
    });

    if (_ref.read(authProvider).status == AuthStatus.authenticated) {
      fetchDebts();
    }
  }

  Future<void> fetchDebts() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.get('/debts');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final debts = data.map((json) => DebtModel.fromJson(json)).toList();
        state = state.copyWith(debts: debts, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error fetching debts: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addDebt(String type, String creditorName, double amount) async {
    try {
      final response = await _apiService.post('/debts', {
        'type': type,
        'creditorName': creditorName,
        'amount': amount,
      });

      if (response.statusCode == 201) {
        await fetchDebts();
        await _ref.read(transactionProvider.notifier).fetchTransactions();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding debt: $e');
    }
    return false;
  }

  Future<bool> payDebt(String id, double amount) async {
    try {
      final response = await _apiService.patch('/debts/$id/pay', {
        'amount': amount,
      });

      if (response.statusCode == 200) {
        await fetchDebts();
        await _ref.read(transactionProvider.notifier).fetchTransactions();
        return true;
      }
    } catch (e) {
      debugPrint('Error paying debt: $e');
    }
    return false;
  }

  Future<bool> deleteDebt(String id) async {
    try {
      final response = await _apiService.delete('/debts/$id');
      if (response.statusCode == 200) {
        await fetchDebts();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting debt: $e');
    }
    return false;
  }
}

final debtProvider = StateNotifierProvider<DebtNotifier, DebtState>((ref) {
  return DebtNotifier(ref);
});
