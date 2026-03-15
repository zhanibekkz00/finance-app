import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import 'auth_provider.dart';

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;
  StreamSubscription? _subscription;

  CategoryNotifier(this._ref) : super([]) {
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
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        _startListening();
      } else if (next.status == AuthStatus.unauthenticated) {
        _unsubscribe();
        state = [];
      }
    });

    final currentAuth = _ref.read(authProvider);
    if (currentAuth.status == AuthStatus.authenticated) {
      _startListening();
    }
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    final auth = _ref.read(authProvider);
    if (auth.userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(auth.userId)
        .collection('categories');
  }

  void _startListening() {
    _unsubscribe();
    final auth = _ref.read(authProvider);
    debugPrint('CategoryNotifier: Starting to listen for user ${auth.userId}');

    _subscription = _collection.snapshots().listen((snapshot) {
      debugPrint(
          'CategoryNotifier: Received snapshot with ${snapshot.docs.length} docs');

      if (snapshot.docs.isEmpty) {
        debugPrint('CategoryNotifier: Snapshot is empty, seeding defaults...');
        _seedDefaults();
        // Set initial state to defaults so user doesn't see empty screen while seeding
        if (state.isEmpty) {
          state = _getDefaultList();
        }
        return;
      }

      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return CategoryModel(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          colorValue: data['colorValue'] ?? 0xFF9E9E9E,
          iconCode: data['iconCode'] ?? 0xe88a,
          isDefault: data['isDefault'] == true || data['isDefault'] == 1,
        );
      }).toList();

      state = categories;
      debugPrint(
          'CategoryNotifier: State updated with ${categories.length} categories');
    }, onError: (e) {
      debugPrint('CategoryNotifier: Snapshot error: $e');
      if (state.isEmpty) {
        state = _getDefaultList();
      }
    });
  }

  List<CategoryModel> _getDefaultList() {
    return [
      CategoryModel(
        id: '1',
        name: 'Еда', // Food
        colorValue: 0xFFF44336,
        iconCode: 0xe25a,
        isDefault: true,
      ),
      CategoryModel(
        id: '2',
        name: 'Развлечения', // Entertainment
        colorValue: 0xFF9C27B0,
        iconCode: 0xe338,
        isDefault: true,
      ),
      CategoryModel(
        id: '3',
        name: 'Поездки', // Trips
        colorValue: 0xFF2196F3,
        iconCode: 0xe539,
        isDefault: true,
      ),
      CategoryModel(
        id: '4',
        name: 'Зарплата', // Salary
        colorValue: 0xFF4CAF50,
        iconCode: 0xe263,
        isDefault: true,
      ),
    ];
  }

  Future<void> _seedDefaults() async {
    try {
      final defaults = _getDefaultList();
      final batch = _firestore.batch();

      for (var cat in defaults) {
        debugPrint('CategoryNotifier: Adding category ${cat.name} to batch...');
        batch.set(_collection.doc(cat.id), {
          'name': cat.name,
          'colorValue': cat.colorValue,
          'iconCode': cat.iconCode,
          'isDefault': cat.isDefault,
        });
      }

      await batch.commit();
      debugPrint('CategoryNotifier: Batch commit successful');
    } catch (e) {
      debugPrint('CategoryNotifier: Error seeding categories: $e');
    }
  }

  Future<void> add(CategoryModel category) async {
    try {
      await _collection.doc(category.id).set({
        'name': category.name,
        'colorValue': category.colorValue,
        'iconCode': category.iconCode,
        'isDefault': category.isDefault,
      });
    } catch (e) {
      debugPrint('CategoryNotifier: Error adding category: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      debugPrint('CategoryNotifier: Error deleting category: $id');
    }
  }

  CategoryModel? getCategoryById(String id) {
    if (state.isEmpty) return null;
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryModel>>((ref) {
  return CategoryNotifier(ref);
});
