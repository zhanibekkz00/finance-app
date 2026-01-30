import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
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

  TransactionState({
    required this.transactions,
    required this.filter,
    this.isLoading = false,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    TransactionFilter? filter,
    bool? isLoading,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;
  StreamSubscription? _subscription;

  TransactionNotifier(this._ref)
      : super(TransactionState(transactions: [], filter: TransactionFilter())) {
    _init();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _init() {
    _ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        _startListening();
      } else {
        _unsubscribe();
        state = state.copyWith(transactions: []);
      }
    });

    if (_ref.read(authProvider).status == AuthStatus.authenticated) {
      _startListening();
    }
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    final auth = _ref.read(authProvider);
    if (auth.userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(auth.userId)
        .collection('transactions');
  }

  void _startListening() {
    _unsubscribe();
    state = state.copyWith(isLoading: true);
    final auth = _ref.read(authProvider);
    debugPrint(
        'TransactionNotifier: Starting to listen for user ${auth.userId}');

    _subscription = _collection
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      debugPrint(
          'TransactionNotifier: Received snapshot with ${snapshot.docs.length} docs');

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: doc.id,
          type:
              TransactionType.values.firstWhere((e) => e.name == data['type']),
          amount: (data['amount'] as num).toDouble(),
          categoryId: data['categoryId'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          note: data['note'] ?? '',
          isRecurring: data['isRecurring'] ?? false,
          currency: data['currency'] ?? 'USD',
          recurrenceInterval: RecurrenceInterval.values.firstWhere(
              (e) => e.name == (data['recurrenceInterval'] ?? 'none')),
          nextOccurrence: data['nextOccurrence'] != null
              ? (data['nextOccurrence'] as Timestamp).toDate()
              : null,
          isPinned: data['isPinned'] ?? false,
        );
      }).toList();

      state = state.copyWith(
        transactions: _sort(transactions),
        isLoading: false,
      );
    }, onError: (e) {
      debugPrint('TransactionNotifier: Snapshot error: $e');
      state = state.copyWith(isLoading: false);
    });
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
      final map = _toFirestoreMap(tx);
      await _collection.doc(tx.id).set(map);
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<void> update(TransactionModel tx) async {
    try {
      await _collection.doc(tx.id).update(_toFirestoreMap(tx));
    } catch (e) {
      debugPrint('Error updating transaction: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting transaction: $id');
    }
  }

  Map<String, dynamic> _toFirestoreMap(TransactionModel tx) {
    return {
      'type': tx.type.name,
      'amount': tx.amount,
      'currency': tx.currency,
      'categoryId': tx.categoryId,
      'date': Timestamp.fromDate(tx.date),
      'note': tx.note,
      'isRecurring': tx.isRecurring,
      'recurrenceInterval': tx.recurrenceInterval.name,
      'nextOccurrence': tx.nextOccurrence != null
          ? Timestamp.fromDate(tx.nextOccurrence!)
          : null,
      'isPinned': tx.isPinned,
    };
  }

  Future<void> togglePin(String id) async {
    final tx = state.transactions.firstWhere((t) => t.id == id);
    await update(tx.copyWith(isPinned: !tx.isPinned));
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
