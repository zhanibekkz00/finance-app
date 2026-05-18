import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

// --- Models ---

class AdminStats {
  final int totalUsers;
  final double totalTransactionVolume;
  final List<MapEntry<String, double>> popularCategories;
  final List<int> newUsersPerDay;

  AdminStats({
    required this.totalUsers,
    required this.totalTransactionVolume,
    required this.popularCategories,
    required this.newUsersPerDay,
  });

  factory AdminStats.fromMap(Map<String, dynamic> data) {
    return AdminStats(
      totalUsers: data['totalUsers'] ?? 0,
      totalTransactionVolume: (data['totalTransactionVolume'] ?? 0).toDouble(),
      popularCategories: (data['popularCategories'] as List? ?? []).map((e) {
        return MapEntry<String, double>(e['key'], (e['value'] ?? 0).toDouble());
      }).toList(),
      newUsersPerDay: List<int>.from(data['newUsersPerDay'] ?? []),
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String role;
  final bool isBlocked;
  final DateTime createdAt;
  final String groupName;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.isBlocked = false,
    required this.createdAt,
    this.groupName = 'No Group',
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'],
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      isBlocked: data['isBlocked'] ?? false,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
      groupName: data['group']?['name'] ?? 'No Group',
    );
  }
}

// --- State ---

class AdminState {
  final bool isLoading;
  final AdminStats? stats;
  final List<UserProfile> users;
  final List<CategoryModel> globalCategories;
  final String? errorMessage;

  AdminState({
    this.isLoading = false,
    this.stats,
    this.users = const [],
    this.globalCategories = const [],
    this.errorMessage,
  });

  AdminState copyWith({
    bool? isLoading,
    AdminStats? stats,
    List<UserProfile>? users,
    List<CategoryModel>? globalCategories,
    String? errorMessage,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      users: users ?? this.users,
      globalCategories: globalCategories ?? this.globalCategories,
      errorMessage: errorMessage,
    );
  }
}

// --- Notifier ---

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiService _apiService = ApiService();

  AdminNotifier() : super(AdminState());

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dashboardResponse = await _apiService.get('/admin/dashboard');
      final usersResponse = await _apiService.get('/admin/users');
      final catsResponse = await _apiService.get('/admin/categories');

      if (dashboardResponse.statusCode == 200 && usersResponse.statusCode == 200) {
        final dashboardData = jsonDecode(dashboardResponse.body);
        final usersData = jsonDecode(usersResponse.body) as List;
        final catsData = catsResponse.statusCode == 200 ? jsonDecode(catsResponse.body) as List : [];

        final users = usersData.map((d) => UserProfile.fromMap(d)).toList();
        final globalCategories = catsData.map((d) => CategoryModel.fromMap(d)).toList();

        state = state.copyWith(
          isLoading: false,
          users: users,
          globalCategories: globalCategories,
          stats: AdminStats.fromMap(dashboardData),
        );
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleUserBlockStatus(String userId, bool currentStatus) async {
    try {
      final response = await _apiService.patch('/admin/users/$userId/block', {
        'isBlocked': !currentStatus,
      });

      if (response.statusCode == 200) {
        final updatedUsers = state.users.map((u) {
          if (u.id == userId) {
            return UserProfile(
              id: u.id,
              email: u.email,
              role: u.role,
              isBlocked: !currentStatus,
              createdAt: u.createdAt,
              groupName: u.groupName,
            );
          }
          return u;
        }).toList();
        state = state.copyWith(users: updatedUsers);
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final response = await _apiService.patch('/admin/users/$userId/role', {
        'role': newRole,
      });

      if (response.statusCode == 200) {
        final updatedUsers = state.users.map((u) {
          if (u.id == userId) {
            return UserProfile(
              id: u.id,
              email: u.email,
              role: newRole,
              isBlocked: u.isBlocked,
              createdAt: u.createdAt,
              groupName: u.groupName,
            );
          }
          return u;
        }).toList();
        state = state.copyWith(users: updatedUsers);
      }
    } catch (e) {
      debugPrint('Error updating role: $e');
    }
  }

  Future<void> addGlobalCategory(CategoryModel category) async {
    try {
      final response = await _apiService.post('/admin/categories', {
        'name': category.name,
        'colorValue': category.colorValue,
        'iconCode': category.iconCode,
        'isDefault': category.isDefault,
      });
      if (response.statusCode != 201) {
         throw Exception('Failed to add category. \nStatus: ${response.statusCode} \nBody: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> sendNotification(String title, String body) async {
    try {
      final response = await _apiService.post('/admin/notifications', {
        'title': title,
        'body': body,
      });
      if (response.statusCode != 201) {
         throw Exception('Failed to send notification.');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  Future<bool> checkIsAdmin(String userId) async {
    try {
      final response = await _apiService.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'] == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
