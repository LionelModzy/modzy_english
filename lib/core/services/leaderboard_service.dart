import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

class LeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get leaderboard by total lessons completed
  static Future<List<UserModel>> getLessonsLeaderboard({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('totalLessonsCompleted', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching lessons leaderboard: $e');
      return [];
    }
  }

  /// Get leaderboard by total vocabulary learned
  static Future<List<UserModel>> getVocabularyLeaderboard({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('totalVocabularyLearned', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching vocabulary leaderboard: $e');
      return [];
    }
  }

  /// Get leaderboard by progress percentage
  static Future<List<UserModel>> getProgressLeaderboard({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('progressPercentage', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching progress leaderboard: $e');
      return [];
    }
  }

  /// Get leaderboard by current level
  static Future<List<UserModel>> getLevelLeaderboard({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('currentLevel', descending: true)
          .orderBy('progressPercentage', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching level leaderboard: $e');
      return [];
    }
  }

  /// Get current user's rank in a leaderboard
  static Future<int> getUserRank({
    required String userId,
    required String sortBy, // 'lessons', 'vocabulary', 'progress', 'level', 'overall'
  }) async {
    try {
      // For overall ranking, we need to calculate all scores
      if (sortBy == 'overall') {
        final allUsers = await getOverallLeaderboard(limit: 1000);
        final userIndex = allUsers.indexWhere((user) => user.uid == userId);
        return userIndex >= 0 ? userIndex + 1 : -1;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return -1;

      final userData = userDoc.data()!;
      final userValue = _getUserValue(userData, sortBy);

      Query query =
          _firestore.collection('users').where('isActive', isEqualTo: true);

      switch (sortBy) {
        case 'lessons':
          query = query.where('totalLessonsCompleted', isGreaterThan: userValue);
          break;
        case 'vocabulary':
          query = query.where('totalVocabularyLearned', isGreaterThan: userValue);
          break;
        case 'progress':
          query = query.where('progressPercentage', isGreaterThan: userValue);
          break;
        case 'level':
          final userLevel = userData['currentLevel'] ?? 1;
          query = query.where('currentLevel', isGreaterThan: userLevel);
          break;
        default:
          return -1;
      }

      final countSnapshot = await query.count().get();
      final count = countSnapshot.count ?? 0;
      return (count + 1).toInt(); // Rank is 1-indexed
    } catch (e) {
      if (kDebugMode) print('Error getting user rank: $e');
      return -1;
    }
  }

  /// Helper method to get user value for comparison
  static dynamic _getUserValue(Map<String, dynamic> userData, String sortBy) {
    switch (sortBy) {
      case 'lessons':
        return userData['totalLessonsCompleted'] ?? 0;
      case 'vocabulary':
        return userData['totalVocabularyLearned'] ?? 0;
      case 'progress':
        return (userData['progressPercentage'] ?? 0.0).toDouble();
      case 'level':
        return userData['currentLevel'] ?? 1;
      default:
        return 0;
    }
  }

  /// Get overall leaderboard (combined score)
  static Future<List<UserModel>> getOverallLeaderboard({
    int limit = 50,
    String timePeriod = 'all', // 'daily', 'weekly', 'monthly', 'yearly', 'all'
  }) async {
    try {
      // Get all active users
      final querySnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      // Calculate combined score for each user
      final usersWithScore = querySnapshot.docs.map((doc) {
        final user = UserModel.fromFirestore(doc);
        final score = _calculateOverallScore(user, timePeriod);
        return {'user': user, 'score': score};
      }).toList();

      // Sort by score descending
      usersWithScore.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // Return top users
      return usersWithScore
          .take(limit)
          .map((item) => item['user'] as UserModel)
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching overall leaderboard: $e');
      return [];
    }
  }

  /// Get leaderboard with time period filter
  static Future<List<UserModel>> getLeaderboardByPeriod({
    required String sortBy, // 'lessons', 'vocabulary', 'progress', 'level', 'overall'
    required String timePeriod, // 'daily', 'weekly', 'monthly', 'yearly', 'all'
    int limit = 50,
  }) async {
    try {
      switch (sortBy) {
        case 'lessons':
          return await getLessonsLeaderboard(limit: limit);
        case 'vocabulary':
          return await getVocabularyLeaderboard(limit: limit);
        case 'progress':
          return await getProgressLeaderboard(limit: limit);
        case 'level':
          return await getLevelLeaderboard(limit: limit);
        case 'overall':
          return await getOverallLeaderboard(limit: limit, timePeriod: timePeriod);
        default:
          return await getOverallLeaderboard(limit: limit, timePeriod: timePeriod);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching leaderboard by period: $e');
      return [];
    }
  }

  /// Calculate overall score based on multiple factors
  static double _calculateOverallScore(UserModel user, [String timePeriod = 'all']) {
    // Weighted scoring:
    // - Lessons: 30%
    // - Vocabulary: 30%
    // - Progress: 20%
    // - Level: 20%
    // Note: Time period filtering would require activity tracking by date
    // For now, we use overall stats. Future enhancement: filter by lastLoginAt or activity dates
    final lessonsScore = user.totalLessonsCompleted * 0.3;
    final vocabScore = user.totalVocabularyLearned * 0.3;
    final progressScore = user.progressPercentage * 0.2;
    final levelScore = user.currentLevel * 20 * 0.2; // Level 1-5, scaled

    // Apply time period multiplier if needed (future enhancement)
    double multiplier = 1.0;
    if (timePeriod != 'all' && user.lastLoginAt != null) {
      final now = DateTime.now();
      final lastLogin = user.lastLoginAt!;
      final daysSinceLogin = now.difference(lastLogin).inDays;
      
      switch (timePeriod) {
        case 'daily':
          multiplier = daysSinceLogin <= 1 ? 1.0 : 0.5;
          break;
        case 'weekly':
          multiplier = daysSinceLogin <= 7 ? 1.0 : 0.5;
          break;
        case 'monthly':
          multiplier = daysSinceLogin <= 30 ? 1.0 : 0.5;
          break;
        case 'yearly':
          multiplier = daysSinceLogin <= 365 ? 1.0 : 0.5;
          break;
      }
    }

    return (lessonsScore + vocabScore + progressScore + levelScore) * multiplier;
  }
}

