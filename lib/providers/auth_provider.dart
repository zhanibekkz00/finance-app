import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? userId;
  final String? role;

  AuthState(
      {this.status = AuthStatus.unauthenticated,
      this.email,
      this.userId,
      this.role});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(AuthState(status: AuthStatus.loading)) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final role = await _fetchUserRole(user.uid);

        state = AuthState(
          status: AuthStatus.authenticated,
          email: user.email,
          userId: user.uid,
          role: role,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Force 'admin' role if specific credentials match
      if (email.trim().toLowerCase() == 'admin@gmail.com' &&
          password == '1234567') {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'role': 'admin'});
      }

      // Explicitly fetch role after login to avoid race condition with stream
      final role = await _fetchUserRole(userCredential.user!.uid);

      state = AuthState(
        status: AuthStatus.authenticated,
        email: userCredential.user!.email,
        userId: userCredential.user!.uid,
        role: role,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      if ((e.code == 'invalid-credential' || e.code == 'user-not-found') &&
          email.trim().toLowerCase() == 'admin@gmail.com' &&
          password == '1234567') {
        debugPrint('Admin account not found, attempting auto-registration...');
        return register(email, password);
      }
      debugPrint('Login error: $e');
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      String role = 'user';
      if (email.trim().toLowerCase() == 'admin@gmail.com' &&
          password == '1234567') {
        role = 'admin';
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isBlocked': false,
      });

      // Explicitly set state with role to ensure UI redirects correctly
      state = AuthState(
        status: AuthStatus.authenticated,
        email: userCredential.user!.email,
        userId: userCredential.user!.uid,
        role: role,
      );

      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<String> _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] ?? 'user';
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }
    return 'user';
  }

  Future<void> logout() async {
    await _auth.signOut();
    // State is updated automatically by authStateChanges listener
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
