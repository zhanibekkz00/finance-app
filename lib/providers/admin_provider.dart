import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

// --- Models ---

class AdminStats {
  final int totalUsers;
  final double totalTransactionVolume;
  final List<MapEntry<String, double>>
      popularCategories; // Category ID -> Amount
  final List<int> newUsersPerDay; // Last 7 days

  AdminStats({
    required this.totalUsers,
    required this.totalTransactionVolume,
    required this.popularCategories,
    required this.newUsersPerDay,
  });
}

class UserProfile {
  final String id;
  final String email;
  final String role; // 'user' or 'admin'
  final bool isBlocked;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.isBlocked = false,
    required this.createdAt,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      isBlocked: data['isBlocked'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'isBlocked': isBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// --- State ---

class AdminState {
  final bool isLoading;
  final AdminStats? stats;
  final List<UserProfile> users;
  final String? errorMessage;

  AdminState({
    this.isLoading = false,
    this.stats,
    this.users = const [],
    this.errorMessage,
  });

  AdminState copyWith({
    bool? isLoading,
    AdminStats? stats,
    List<UserProfile>? users,
    String? errorMessage,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      users: users ?? this.users,
      errorMessage: errorMessage,
    );
  }
}

// --- Notifier ---

class AdminNotifier extends StateNotifier<AdminState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminNotifier() : super(AdminState());

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Fetch Users
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs
          .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
          .toList();

      // 2. Fetch Transactions for Stats
      // Note: In a real large-scale app, we would use aggregated counters.
      // Fetching all transactions is expensive but requested here.
      final txSnapshot = await _firestore.collection('transactions').get();
      final transactions = txSnapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: doc.id,
          type: TransactionType.values.firstWhere(
              (e) => e.name == (data['type'] ?? 'expense'),
              orElse: () => TransactionType.expense),
          amount: (data['amount'] as num).toDouble(),
          categoryId: data['categoryId'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          note: '',
          isRecurring: false,
          userId: data['userId'],
        );
      }).toList();

      // Calculate Stats
      double totalVolume = 0;
      final categorySpending = <String, double>{};

      for (var tx in transactions) {
        totalVolume += tx.amount;
        if (tx.type == TransactionType.expense) {
          categorySpending.update(
            tx.categoryId,
            (value) => value + tx.amount,
            ifAbsent: () => tx.amount,
          );
        }
      }

      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final popularCategories = sortedCategories.take(5).toList();

      // New users last 7 days (mock logic if dates aren't perfect, but trying real)
      final now = DateTime.now();
      final last7Days = List.generate(7, (index) {
        final day = now.subtract(Duration(days: index));
        return users
            .where((u) =>
                u.createdAt.year == day.year &&
                u.createdAt.month == day.month &&
                u.createdAt.day == day.day)
            .length;
      }).reversed.toList();

      state = state.copyWith(
        isLoading: false,
        users: users,
        stats: AdminStats(
          totalUsers: users.length,
          totalTransactionVolume: totalVolume,
          popularCategories: popularCategories,
          newUsersPerDay: last7Days,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleUserBlockStatus(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': !currentStatus,
      });
      // specific user update locally to avoid full reload
      final updatedUsers = state.users.map((u) {
        if (u.id == userId) {
          return UserProfile(
            id: u.id,
            email: u.email,
            role: u.role,
            isBlocked: !currentStatus,
            createdAt: u.createdAt,
          );
        }
        return u;
      }).toList();
      state = state.copyWith(users: updatedUsers);
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      final updatedUsers = state.users.map((u) {
        if (u.id == userId) {
          return UserProfile(
            id: u.id,
            email: u.email,
            role: newRole,
            isBlocked: u.isBlocked,
            createdAt: u.createdAt,
          );
        }
        return u;
      }).toList();
      state = state.copyWith(users: updatedUsers);
    } catch (e) {
      debugPrint('Error updating role: $e');
    }
  }

  Future<void> addGlobalCategory(CategoryModel category) async {
    try {
      await _firestore.collection('categories').add({
        ...category.toMap(),
        'isGlobal': true, // Explicitly mark as global
      });
    } catch (e) {
      debugPrint('Error adding category: $e');
      throw e;
    }
  }

  Future<void> sendNotification(String title, String body) async {
    try {
      // 1. Queue for push delivery (handled by Cloud Functions normally)
      await _firestore.collection('notifications_queue').add({
        'title': title,
        'body': body,
        'target': 'all',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // 2. Save to persistent history for users to read in-app
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
      throw e;
    }
  }

  // Method to check if current user is admin
  Future<bool> checkIsAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      return doc.data()?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
