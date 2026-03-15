import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/group_service.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;
  final GroupService _groupService = GroupService();
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
        state = state.copyWith(transactions: [], currentGroupId: null);
      }
    });

    if (_ref.read(authProvider).status == AuthStatus.authenticated) {
      _startListening();
    }
  }

  /// Returns the top-level transactions collection
  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection('transactions');
  }

  Future<void> _startListening() async {
    _unsubscribe();
    state = state.copyWith(isLoading: true);

    final auth = _ref.read(authProvider);
    if (auth.userId == null) return;

    debugPrint('TransactionNotifier: Starting setup for user ${auth.userId}');

    // 1. Determine Group ID
    String? groupId = await _groupService.getUserGroupId(auth.userId!);
    state = state.copyWith(currentGroupId: groupId);

    debugPrint('TransactionNotifier: Group ID is $groupId');

    // 2. Build Query
    Query<Map<String, dynamic>> query = _collection;

    if (groupId != null) {
      // If in a group, fetch all transactions for that group
      query = query.where('groupId', isEqualTo: groupId);
    } else {
      // Otherwise, fetch private transactions for this user
      // Note: This relies on legacy transactions effectively being "private" or migrated.
      // Ideally, legacy data would be backfilled with userId.
      query = query.where('userId', isEqualTo: auth.userId);
    }

    // Apply sorting
    query = query.orderBy('date', descending: true);

    _subscription = query.snapshots().listen((snapshot) {
      debugPrint(
          'TransactionNotifier: Received snapshot with ${snapshot.docs.length} docs');

      if (snapshot.docs.isEmpty) {
        debugPrint(
            'TransactionNotifier: No transactions found for this ${groupId != null ? "group" : "user"}. Path: transactions, groupId: $groupId, userId: ${auth.userId}');
      }

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('TransactionNotifier: Found doc ${doc.id}');
        return TransactionModel(
          id: doc.id,
          type:
              TransactionType.values.firstWhere((e) => e.name == data['type']),
          amount: (data['amount'] as num).toDouble(),
          categoryId: data['categoryId'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          note: data['note'] ?? '',
          isRecurring:
              (data['isRecurring'] == true || data['isRecurring'] == 1),
          currency: data['currency'] ?? 'USD',
          recurrenceInterval: RecurrenceInterval.values.firstWhere(
              (e) => e.name == (data['recurrenceInterval'] ?? 'none')),
          nextOccurrence: data['nextOccurrence'] != null
              ? (data['nextOccurrence'] as Timestamp).toDate()
              : null,
          isPinned: (data['isPinned'] == true || data['isPinned'] == 1),
          userId: data['userId'],
          groupId: data['groupId'],
        );
      }).toList();

      state = state.copyWith(
        transactions: _sort(transactions),
        isLoading: false,
      );
    }, onError: (e) {
      debugPrint('TransactionNotifier: Snapshot error type: ${e.runtimeType}');
      debugPrint('TransactionNotifier: Snapshot error details: $e');
      // Look for a link in this error - it might be a missing index!
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
      final auth = _ref.read(authProvider);
      if (auth.userId == null) throw Exception('User not authenticated');

      // Refresh group ID to be safe, or use cached state
      String? groupId = state.currentGroupId;
      // If state might be stale, could refetch: await _groupService.getUserGroupId(auth.userId!);

      final newTx = tx.copyWith(
        userId: auth.userId,
        groupId: groupId,
      );

      final map = _toFirestoreMap(newTx);
      // We use add() to let Firestore generate the ID, or set() if ID is pre-generated/provided
      if (newTx.id.isNotEmpty && newTx.id != 'new') {
        await _collection.doc(newTx.id).set(map);
      } else {
        await _collection.add(map);
      }
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
    final map = tx.toMap();
    // Use Timestamps for better Firestore sorting and indexing
    map['date'] = Timestamp.fromDate(tx.date);
    if (tx.nextOccurrence != null) {
      map['nextOccurrence'] = Timestamp.fromDate(tx.nextOccurrence!);
    }
    return map;
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
