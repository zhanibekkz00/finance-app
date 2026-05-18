import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? userId;
  final String? role;
  final String? displayName;

  AuthState({
    this.status = AuthStatus.unauthenticated,
    this.email,
    this.userId,
    this.role,
    this.displayName,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();

  AuthNotifier() : super(AuthState(status: AuthStatus.loading)) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      await fetchProfile();
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiService.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = AuthState(
          status: AuthStatus.authenticated,
          email: data['email'],
          userId: data['id'],
          role: data['role'] ?? 'user',
          displayName: data['displayName'],
        );
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    if (email == 'admin') email = 'admin@admin.com';
    state = AuthState(status: AuthStatus.loading);
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        await fetchProfile();
        return true;
      }
      state = AuthState(status: AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      // Create user
      final response = await _apiService.post('/auth/register', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        await fetchProfile();
        return true;
      }
      state = AuthState(status: AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    try {
      final response = await _apiService.patch('/auth/profile', {
        if (displayName != null) 'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });

      if (response.statusCode == 200) {
        await fetchProfile();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
