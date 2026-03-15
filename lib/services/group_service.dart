import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a random 6-character alphanumeric code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  // Create a new group
  Future<String?> createGroup(String ownerId) async {
    try {
      String inviteCode = _generateInviteCode();

      // Ensure code uniqueness (simplistic check for now)
      // Retry if client is offline (common on Web startup)
      QuerySnapshot<Map<String, dynamic>>? existing;
      int retries = 0;
      while (retries < 3) {
        try {
          existing = await _firestore
              .collection('groups')
              .where('inviteCode', isEqualTo: inviteCode)
              .get()
              .timeout(const Duration(seconds: 10));
          break;
        } catch (e) {
          if (e.toString().contains('unavailable') ||
              e.toString().contains('offline')) {
            retries++;
            debugPrint('Firestore unavailable, retry $retries/3...');
            await Future.delayed(Duration(seconds: 2 * retries));
          } else {
            rethrow;
          }
        }
      }

      if (existing == null) throw Exception('Could not connect to Firestore');

      while (existing!.docs.isNotEmpty) {
        inviteCode = _generateInviteCode();
        existing = await _firestore
            .collection('groups')
            .where('inviteCode', isEqualTo: inviteCode)
            .get()
            .timeout(const Duration(seconds: 10));
      }

      final groupRef = await _firestore.collection('groups').add({
        'ownerId': ownerId,
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [ownerId],
      });

      // Update the creator's user document with the new groupId
      await _firestore.collection('users').doc(ownerId).set({
        'groupId': groupRef.id,
      }, SetOptions(merge: true));

      return inviteCode;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return null;
    }
  }

  // Join an existing group using the invite code
  Future<bool> joinGroup(String userId, String inviteCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (querySnapshot.docs.isEmpty) {
        return false; // Group not found
      }

      final groupDoc = querySnapshot.docs.first;
      final groupId = groupDoc.id;

      // Add user to group members list
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId])
      });

      // Update user's groupId
      await _firestore.collection('users').doc(userId).set({
        'groupId': groupId,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Error joining group: $e');
      return false;
    }
  }

  // Get the group ID for a specific user
  Future<String?> getUserGroupId(String userId) async {
    int retries = 0;
    while (retries < 3) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .get()
            .timeout(const Duration(seconds: 5));
        if (doc.exists && doc.data()!.containsKey('groupId')) {
          return doc.data()!['groupId'] as String?;
        }
        return null;
      } catch (e) {
        if (e.toString().contains('unavailable') ||
            e.toString().contains('offline')) {
          retries++;
          debugPrint(
              'getUserGroupId: Firestore unavailable, retry $retries/3...');
          await Future.delayed(Duration(seconds: 1 * retries));
        } else {
          debugPrint('Error fetching user group ID: $e');
          return null;
        }
      }
    }
    return null;
  }

  // Get the invite code for a specific group
  Future<String?> getGroupCode(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists && doc.data()!.containsKey('inviteCode')) {
        return doc.data()!['inviteCode'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching group code: $e');
      return null;
    }
  }
}
