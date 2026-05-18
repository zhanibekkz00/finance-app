import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final apiService = ApiService();
  final response = await apiService.get('/notifications');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return data.map((e) => NotificationModel.fromMap(e)).toList();
  } else {
    throw Exception('Failed to load notifications');
  }
});
