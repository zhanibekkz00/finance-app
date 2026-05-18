import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _apiService = ApiService();

  // Create a new group
  Future<String?> createGroup(String ownerId, {String name = 'My Group'}) async {
    try {
      final response = await _apiService.post('/groups', {'name': name});
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['joinCode']; // Returns the invite code from backend
      }
      return null;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return null;
    }
  }

  // Join an existing group using the invite code
  Future<bool> joinGroup(String userId, String inviteCode) async {
    try {
      final response = await _apiService.post('/groups/join', {'joinCode': inviteCode});
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error joining group: $e');
      return false;
    }
  }

  // Get the group ID for a specific user
  Future<String?> getUserGroupId(String userId) async {
    try {
      final response = await _apiService.get('/groups/me');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['id'] != null) {
          return data['id'] as String;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user group ID: $e');
      return null;
    }
  }

  // Get the invite code for a specific group (now just calls /groups/me)
  Future<String?> getGroupCode(String groupId) async {
    try {
      final response = await _apiService.get('/groups/me');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['joinCode'] != null) {
          return data['joinCode'] as String;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching group code: $e');
      return null;
    }
  }
}
