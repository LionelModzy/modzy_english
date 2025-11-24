import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_model.dart';

class FriendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  static Future<List<UserModel>> getFriends(String userId) async {
    try {
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final friendIds = List<String>.from(data['friends'] ?? <String>[]);
      if (friendIds.isEmpty) return [];

      final friends = <UserModel>[];
      const chunkSize = 10; // Firestore whereIn limit

      for (var i = 0; i < friendIds.length; i += chunkSize) {
        final chunk = friendIds.sublist(i, math.min(i + chunkSize, friendIds.length));
        final querySnapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        friends.addAll(querySnapshot.docs.map(UserModel.fromFirestore));
      }

      return friends;
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching friends: $e');
      return [];
    }
  }

  static Future<bool> areFriends({
    required String userId,
    required String friendUserId,
  }) async {
    try {
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!userDoc.exists) return false;
      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final friendIds = List<String>.from(data['friends'] ?? <String>[]);
      return friendIds.contains(friendUserId);
    } catch (e) {
      if (kDebugMode) print('❌ Error checking friendship: $e');
      return false;
    }
  }

  static Future<bool> linkFriends({
    required String currentUserId,
    required String friendUserId,
  }) async {
    if (currentUserId == friendUserId) return false;

    try {
      await _firestore.runTransaction((transaction) async {
        final currentRef = _firestore.collection(_usersCollection).doc(currentUserId);
        final friendRef = _firestore.collection(_usersCollection).doc(friendUserId);

        final currentSnapshot = await transaction.get(currentRef);
        final friendSnapshot = await transaction.get(friendRef);

        if (!currentSnapshot.exists || !friendSnapshot.exists) {
          throw Exception('User not found');
        }

        final currentFriends = List<String>.from(currentSnapshot.data()?['friends'] ?? <String>[]);
        if (currentFriends.contains(friendUserId)) {
          return;
        }

        transaction.update(currentRef, {
          'friends': FieldValue.arrayUnion([friendUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(friendRef, {
          'friends': FieldValue.arrayUnion([currentUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

      });
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error linking friends: $e');
      return false;
    }
  }

  static Future<bool> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final currentRef = _firestore.collection(_usersCollection).doc(currentUserId);
        final friendRef = _firestore.collection(_usersCollection).doc(friendUserId);

        // Ensure both docs exist
        final currentSnapshot = await transaction.get(currentRef);
        final friendSnapshot = await transaction.get(friendRef);
        if (!currentSnapshot.exists || !friendSnapshot.exists) return;

        transaction.update(currentRef, {
          'friends': FieldValue.arrayRemove([friendUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(friendRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error removing friend: $e');
      return false;
    }
  }

  static Future<UserModel?> findUserByEmailOrId(String value) async {
    final rawQuery = value.trim();
    if (rawQuery.isEmpty) return null;

    try {
      // Try friend code (uid)
      final directDoc = await _firestore.collection(_usersCollection).doc(rawQuery).get();
      if (directDoc.exists) {
        return UserModel.fromFirestore(directDoc);
      }

      // Try exact email match
      final emailSnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: rawQuery)
          .limit(1)
          .get();
      if (emailSnapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(emailSnapshot.docs.first);
      }

      // Try lowercase email match if stored email was normalized
      final lowerQuery = rawQuery.toLowerCase();
      if (lowerQuery != rawQuery) {
        final lowerSnapshot = await _firestore
            .collection(_usersCollection)
            .where('email', isEqualTo: lowerQuery)
            .limit(1)
            .get();
        if (lowerSnapshot.docs.isNotEmpty) {
          return UserModel.fromFirestore(lowerSnapshot.docs.first);
        }
      }

      // Fallback: scan recent users for case-insensitive matches
      final fallbackSnapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      for (final doc in fallbackSnapshot.docs) {
        final user = UserModel.fromFirestore(doc);
        if (user.email.toLowerCase() == lowerQuery ||
            user.displayName.toLowerCase() == lowerQuery) {
          return user;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error finding user: $e');
      return null;
    }
  }
}

