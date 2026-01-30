import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? userId;

  AuthState(
      {this.status = AuthStatus.unauthenticated, this.email, this.userId});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthNotifier() : super(AuthState(status: AuthStatus.loading)) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          email: user.email,
          userId: user.uid,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // State is updated automatically by authStateChanges listener
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      // State is updated automatically by authStateChanges listener
      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    // State is updated automatically by authStateChanges listener
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
