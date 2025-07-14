import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

class UserManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'users';

  /// Get all users for admin panel
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching users: $e');
      return [];
    }
  }

  /// Get users with pagination
  static Future<List<UserModel>> getUsersPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? role, // Filter by role
    bool? isActive, // Filter by active status
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true);

      // Apply filters
      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching paginated users: $e');
      return [];
    }
  }

  /// Search users by name or email
  static Future<List<UserModel>> searchUsers(String searchQuery) async {
    try {
      if (searchQuery.isEmpty) return getAllUsers();

      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      final allUsers = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Filter users based on search query
      return allUsers.where((user) {
        final query = searchQuery.toLowerCase();
        return user.displayName.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query) ||
               user.uid.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error searching users: $e');
      return [];
    }
  }

  /// Update user role (admin/user)
  static Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) print('✅ User role updated successfully: $userId -> $newRole');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating user role: $e');
      return false;
    }
  }

  /// Activate/Deactivate user account
  static Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) print('✅ User status updated successfully: $userId -> ${isActive ? "active" : "inactive"}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating user status: $e');
      return false;
    }
  }

  /// Update user profile information
  static Future<bool> updateUserProfile(String userId, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(_collection).doc(userId).update(updateData);
      
      if (kDebugMode) print('✅ User profile updated successfully: $userId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating user profile: $e');
      return false;
    }
  }

  /// Delete user account (admin only)
  static Future<bool> deleteUser(String userId) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection(_collection).doc(userId).delete();
      
      // Note: Deleting from Firebase Auth requires admin SDK on server side
      // For now, we just deactivate the account in Firestore
      
      if (kDebugMode) print('✅ User account deleted successfully: $userId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting user: $e');
      return false;
    }
  }

  /// Get user statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      final totalUsers = users.length;
      final activeUsers = users.where((user) => user.isActive).length;
      final inactiveUsers = totalUsers - activeUsers;
      final adminUsers = users.where((user) => user.isAdmin).length;
      final regularUsers = users.where((user) => user.isUser).length;

      // Calculate new users this month
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final newUsersThisMonth = users.where((user) => 
          user.createdAt.isAfter(firstDayOfMonth)).length;

      // Calculate average progress
      final avgProgress = users.isNotEmpty 
          ? users.map((user) => user.progressPercentage).reduce((a, b) => a + b) / users.length
          : 0.0;

      // Calculate average lessons completed
      final avgLessonsCompleted = users.isNotEmpty
          ? users.map((user) => user.totalLessonsCompleted).reduce((a, b) => a + b) / users.length
          : 0.0;

      // Calculate average vocabulary learned
      final avgVocabularyLearned = users.isNotEmpty
          ? users.map((user) => user.totalVocabularyLearned).reduce((a, b) => a + b) / users.length
          : 0.0;

      // Level distribution
      final levelDistribution = <int, int>{};
      for (final user in users) {
        levelDistribution[user.currentLevel] = (levelDistribution[user.currentLevel] ?? 0) + 1;
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'inactiveUsers': inactiveUsers,
        'adminUsers': adminUsers,
        'regularUsers': regularUsers,
        'newUsersThisMonth': newUsersThisMonth,
        'averageProgress': avgProgress,
        'averageLessonsCompleted': avgLessonsCompleted,
        'averageVocabularyLearned': avgVocabularyLearned,
        'levelDistribution': levelDistribution,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting user statistics: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'inactiveUsers': 0,
        'adminUsers': 0,
        'regularUsers': 0,
        'newUsersThisMonth': 0,
        'averageProgress': 0.0,
        'averageLessonsCompleted': 0.0,
        'averageVocabularyLearned': 0.0,
        'levelDistribution': <int, int>{},
        'error': true,
      };
    }
  }

  /// Get user activity data for charts
  static Future<Map<String, dynamic>> getUserActivityData() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Daily registrations for the last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      final dailyRegistrations = <String, int>{};
      for (int i = 0; i < 30; i++) {
        final date = thirtyDaysAgo.add(Duration(days: i));
        final dateKey = '${date.day}/${date.month}';
        dailyRegistrations[dateKey] = 0;
      }

      for (final user in users) {
        if (user.createdAt.isAfter(thirtyDaysAgo)) {
          final dateKey = '${user.createdAt.day}/${user.createdAt.month}';
          dailyRegistrations[dateKey] = (dailyRegistrations[dateKey] ?? 0) + 1;
        }
      }

      // Monthly registrations for the last 12 months
      final monthlyRegistrations = <String, int>{};
      for (int i = 0; i < 12; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = '${date.month}/${date.year}';
        monthlyRegistrations[monthKey] = 0;
      }

      for (final user in users) {
        final monthKey = '${user.createdAt.month}/${user.createdAt.year}';
        if (monthlyRegistrations.containsKey(monthKey)) {
          monthlyRegistrations[monthKey] = (monthlyRegistrations[monthKey] ?? 0) + 1;
        }
      }

      return {
        'dailyRegistrations': dailyRegistrations,
        'monthlyRegistrations': monthlyRegistrations,
        'totalUsers': users.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting user activity data: $e');
      return {
        'dailyRegistrations': <String, int>{},
        'monthlyRegistrations': <String, int>{},
        'totalUsers': 0,
        'error': true,
      };
    }
  }

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['role'] == 'admin';
    } catch (e) {
      if (kDebugMode) print('❌ Error checking admin status: $e');
      return false;
    }
  }

  /// Send notification to user (placeholder for future implementation)
  static Future<bool> sendNotificationToUser(String userId, Map<String, dynamic> notification) async {
    try {
      // This would integrate with FCM or in-app notification system
      // For now, just log the action
      if (kDebugMode) print('📨 Notification sent to user $userId: ${notification['title']}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Bulk update users (for batch operations)
  static Future<int> bulkUpdateUsers(List<String> userIds, Map<String, dynamic> updateData) async {
    try {
      int successCount = 0;
      final batch = _firestore.batch();
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      for (final userId in userIds) {
        final userRef = _firestore.collection(_collection).doc(userId);
        batch.update(userRef, updateData);
      }

      await batch.commit();
      successCount = userIds.length;

      if (kDebugMode) print('✅ Bulk update completed: $successCount users updated');
      return successCount;
    } catch (e) {
      if (kDebugMode) print('❌ Error in bulk update: $e');
      return 0;
    }
  }
} 