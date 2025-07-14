import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_model.dart';
import '../../models/vocab_model.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive platform statistics
  static Future<Map<String, dynamic>> getPlatformStatistics() async {
    try {
      // Get all data in parallel for better performance
      final results = await Future.wait([
        _getUserStatistics(),
        _getLessonStatistics(),
        _getQuizStatistics(),
        _getVocabularyStatistics(),
        _getGrowthMetrics(),
      ]);

      return {
        'users': results[0],
        'lessons': results[1],
        'quizzes': results[2],
        'vocabulary': results[3],
        'growth': results[4],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting platform statistics: $e');
      return {
        'error': true,
        'message': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get user-related statistics
  static Future<Map<String, dynamic>> _getUserStatistics() async {
    try {
      final userSnapshot = await _firestore.collection('users').get();
      final users = userSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      return {
        'total': users.length,
        'active': users.where((u) => u.isActive).length,
        'inactive': users.where((u) => !u.isActive).length,
        'admins': users.where((u) => u.isAdmin).length,
        'newThisMonth': users.where((u) => u.createdAt.isAfter(thirtyDaysAgo)).length,
        'newThisWeek': users.where((u) => u.createdAt.isAfter(sevenDaysAgo)).length,
        'averageProgress': users.isNotEmpty 
            ? users.map((u) => u.progressPercentage).reduce((a, b) => a + b) / users.length
            : 0.0,
        'levelDistribution': _calculateLevelDistribution(users),
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting user statistics: $e');
      return {'error': true};
    }
  }

  /// Get lesson-related statistics
  static Future<Map<String, dynamic>> _getLessonStatistics() async {
    try {
      final lessonSnapshot = await _firestore.collection('lessons').get();
      final lessons = lessonSnapshot.docs;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get lesson completion data
      final progressSnapshot = await _firestore.collection('learning_progress').get();
      final completions = progressSnapshot.docs;

      final totalLessons = lessons.length;
      final activeLessons = lessons.where((doc) {
        final data = doc.data();
        return data['isActive'] == true;
      }).length;

      final newLessonsThisMonth = lessons.where((doc) {
        final data = doc.data();
        if (data['createdAt'] == null) return false;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(thirtyDaysAgo);
      }).length;

      // Calculate completion metrics
      final totalCompletions = completions.length;
      final recentCompletions = completions.where((doc) {
        final data = doc.data();
        if (data['completedAt'] == null) return false;
        final completedAt = (data['completedAt'] as Timestamp).toDate();
        return completedAt.isAfter(thirtyDaysAgo);
      }).length;

      // Calculate average completion rate
      final completionsByLesson = <String, int>{};
      for (final completion in completions) {
        final data = completion.data();
        final lessonId = data['lessonId'] as String?;
        if (lessonId != null) {
          completionsByLesson[lessonId] = (completionsByLesson[lessonId] ?? 0) + 1;
        }
      }

      final avgCompletionsPerLesson = completionsByLesson.isNotEmpty
          ? completionsByLesson.values.reduce((a, b) => a + b) / completionsByLesson.length
          : 0.0;

      return {
        'total': totalLessons,
        'active': activeLessons,
        'inactive': totalLessons - activeLessons,
        'newThisMonth': newLessonsThisMonth,
        'totalCompletions': totalCompletions,
        'recentCompletions': recentCompletions,
        'averageCompletionsPerLesson': avgCompletionsPerLesson,
        'completionsByLesson': completionsByLesson,
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting lesson statistics: $e');
      return {'error': true};
    }
  }

  /// Get quiz-related statistics
  static Future<Map<String, dynamic>> _getQuizStatistics() async {
    try {
      final quizSnapshot = await _firestore.collection('quizzes').get();
      final quizzes = quizSnapshot.docs;

      final resultSnapshot = await _firestore.collection('quiz_results').get();
      final results = resultSnapshot.docs;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final totalQuizzes = quizzes.length;
      final activeQuizzes = quizzes.where((doc) {
        final data = doc.data();
        return data['isActive'] == true;
      }).length;

      final newQuizzesThisMonth = quizzes.where((doc) {
        final data = doc.data();
        if (data['createdAt'] == null) return false;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(thirtyDaysAgo);
      }).length;

      // Calculate quiz attempt metrics
      final totalAttempts = results.length;
      final recentAttempts = results.where((doc) {
        final data = doc.data();
        if (data['completedAt'] == null) return false;
        final completedAt = (data['completedAt'] as Timestamp).toDate();
        return completedAt.isAfter(thirtyDaysAgo);
      }).length;

      // Calculate pass rate
      final passedAttempts = results.where((doc) {
        final data = doc.data();
        return data['passed'] == true;
      }).length;

      final passRate = totalAttempts > 0 ? (passedAttempts / totalAttempts) * 100 : 0.0;

      // Calculate average score
      final scores = results.map((doc) {
        final data = doc.data();
        final percentage = data['percentage'] ?? 0.0;
        // Safe conversion to double regardless of whether it's int or double
        return percentage is double ? percentage : (percentage as num).toDouble();
      }).toList();

      final averageScore = scores.isNotEmpty
          ? scores.reduce((a, b) => a + b) / scores.length
          : 0.0;

      // Quiz difficulty distribution
      final difficultyDistribution = <String, int>{};
      for (final quiz in quizzes) {
        final data = quiz.data();
        final difficulty = data['difficultyLevel'] ?? 1;
        final difficultyKey = difficulty.toString(); // Convert int to string for consistency
        difficultyDistribution[difficultyKey] = (difficultyDistribution[difficultyKey] ?? 0) + 1;
      }

      return {
        'total': totalQuizzes,
        'active': activeQuizzes,
        'inactive': totalQuizzes - activeQuizzes,
        'newThisMonth': newQuizzesThisMonth,
        'totalAttempts': totalAttempts,
        'recentAttempts': recentAttempts,
        'passRate': passRate,
        'averageScore': averageScore,
        'difficultyDistribution': difficultyDistribution,
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting quiz statistics: $e');
      return {'error': true};
    }
  }

  /// Get vocabulary-related statistics
  static Future<Map<String, dynamic>> _getVocabularyStatistics() async {
    try {
      final vocabSnapshot = await _firestore.collection('vocabulary').get();
      final vocabulary = vocabSnapshot.docs;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final totalWords = vocabulary.length;
      final activeWords = vocabulary.where((doc) {
        final data = doc.data();
        return data['isActive'] != false;
      }).length;

      final newWordsThisMonth = vocabulary.where((doc) {
        final data = doc.data();
        if (data['createdAt'] == null) return false;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(thirtyDaysAgo);
      }).length;

      // Category distribution
      final categoryDistribution = <String, int>{};
      for (final word in vocabulary) {
        final data = word.data();
        final category = data['category'] ?? 'Uncategorized';
        categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
      }

      // Difficulty distribution
      final difficultyDistribution = <String, int>{};
      for (final word in vocabulary) {
        final data = word.data();
        final difficulty = data['difficulty'] ?? 'beginner';
        difficultyDistribution[difficulty] = (difficultyDistribution[difficulty] ?? 0) + 1;
      }

      return {
        'total': totalWords,
        'active': activeWords,
        'inactive': totalWords - activeWords,
        'newThisMonth': newWordsThisMonth,
        'categoryDistribution': categoryDistribution,
        'difficultyDistribution': difficultyDistribution,
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting vocabulary statistics: $e');
      return {'error': true};
    }
  }

  /// Get growth metrics over time
  static Future<Map<String, dynamic>> _getGrowthMetrics() async {
    try {
      final now = DateTime.now();
      
      // User growth over last 12 months
      final userGrowth = await _calculateMonthlyGrowth('users', 12);
      
      // Lesson completion growth over last 12 months
      final lessonGrowth = await _calculateMonthlyGrowth('learning_progress', 12);
      
      // Quiz attempt growth over last 12 months
      final quizGrowth = await _calculateMonthlyGrowth('quiz_results', 12);

      // Calculate week-over-week and month-over-month growth
      final lastWeek = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));
      final lastMonth = DateTime(now.year, now.month - 1, now.day);
      final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);

      final userSnapshot = await _firestore.collection('users').get();
      final users = userSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      final usersThisWeek = users.where((u) => u.createdAt.isAfter(lastWeek)).length;
      final usersLastWeek = users.where((u) => 
          u.createdAt.isAfter(twoWeeksAgo) && u.createdAt.isBefore(lastWeek)).length;
      
      final usersThisMonth = users.where((u) => u.createdAt.isAfter(lastMonth)).length;
      final usersLastMonth = users.where((u) => 
          u.createdAt.isAfter(twoMonthsAgo) && u.createdAt.isBefore(lastMonth)).length;

      final weeklyGrowthRate = usersLastWeek > 0 
          ? ((usersThisWeek - usersLastWeek) / usersLastWeek * 100)
          : 0.0;
      
      final monthlyGrowthRate = usersLastMonth > 0 
          ? ((usersThisMonth - usersLastMonth) / usersLastMonth * 100)
          : 0.0;

      return {
        'userGrowth': userGrowth,
        'lessonGrowth': lessonGrowth,
        'quizGrowth': quizGrowth,
        'weeklyGrowthRate': weeklyGrowthRate,
        'monthlyGrowthRate': monthlyGrowthRate,
        'usersThisWeek': usersThisWeek,
        'usersLastWeek': usersLastWeek,
        'usersThisMonth': usersThisMonth,
        'usersLastMonth': usersLastMonth,
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting growth metrics: $e');
      return {'error': true};
    }
  }

  /// Calculate monthly growth for a collection
  static Future<Map<String, int>> _calculateMonthlyGrowth(String collection, int months) async {
    try {
      final now = DateTime.now();
      final monthlyData = <String, int>{};

      for (int i = 0; i < months; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);
        
        final snapshot = await _firestore
            .collection(collection)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
            .where('createdAt', isLessThan: Timestamp.fromDate(nextMonth))
            .get();

        final monthKey = '${month.month}/${month.year}';
        monthlyData[monthKey] = snapshot.docs.length;
      }

      return monthlyData;
    } catch (e) {
      if (kDebugMode) print('❌ Error calculating monthly growth for $collection: $e');
      return {};
    }
  }

  /// Calculate level distribution for users
  static Map<String, int> _calculateLevelDistribution(List<UserModel> users) {
    final distribution = <String, int>{};
    for (final user in users) {
      final levelKey = user.currentLevel.toString(); // Convert int to string for consistency
      distribution[levelKey] = (distribution[levelKey] ?? 0) + 1;
    }
    return distribution;
  }

  /// Get engagement metrics
  static Future<Map<String, dynamic>> getEngagementMetrics() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Daily active users (users who completed lessons or quizzes in last 7 days)
      final lessonProgress = await _firestore
          .collection('learning_progress')
          .where('completedAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final quizResults = await _firestore
          .collection('quiz_results')
          .where('completedAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final activeUserIds = <String>{};
      for (final doc in lessonProgress.docs) {
        final data = doc.data();
        if (data['userId'] != null) {
          activeUserIds.add(data['userId']);
        }
      }
      for (final doc in quizResults.docs) {
        final data = doc.data();
        if (data['userId'] != null) {
          activeUserIds.add(data['userId']);
        }
      }

      final dailyActiveUsers = activeUserIds.length;

      // Calculate session duration (placeholder - would need real session tracking)
      final avgSessionDuration = 8.5; // minutes (placeholder)

      // Calculate retention rate (users who were active 30 days ago and still active)
      final oldActiveProgress = await _firestore
          .collection('learning_progress')
          .where('completedAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .where('completedAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final oldActiveUserIds = <String>{};
      for (final doc in oldActiveProgress.docs) {
        final data = doc.data();
        if (data['userId'] != null) {
          oldActiveUserIds.add(data['userId']);
        }
      }

      final retainedUsers = activeUserIds.intersection(oldActiveUserIds).length;
      final retentionRate = oldActiveUserIds.isNotEmpty 
          ? (retainedUsers / oldActiveUserIds.length) * 100
          : 0.0;

      return {
        'dailyActiveUsers': dailyActiveUsers,
        'averageSessionDuration': avgSessionDuration,
        'retentionRate': retentionRate,
        'retainedUsers': retainedUsers,
        'previousActiveUsers': oldActiveUserIds.length,
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting engagement metrics: $e');
      return {'error': true};
    }
  }

  /// Get revenue metrics (placeholder for future monetization)
  static Future<Map<String, dynamic>> getRevenueMetrics() async {
    // Placeholder for future premium features, subscriptions, etc.
    return {
      'totalRevenue': 0.0,
      'monthlyRecurringRevenue': 0.0,
      'averageRevenuePerUser': 0.0,
      'conversionRate': 0.0,
      'placeholder': true,
    };
  }

  /// Export analytics data to CSV format (returns CSV string)
  static Future<String> exportAnalyticsToCSV() async {
    try {
      final stats = await getPlatformStatistics();
      
      final csvData = StringBuffer();
      csvData.writeln('Metric,Value,Category');
      
      // User metrics
      final users = stats['users'] as Map<String, dynamic>;
      csvData.writeln('Total Users,${users['total']},Users');
      csvData.writeln('Active Users,${users['active']},Users');
      csvData.writeln('Inactive Users,${users['inactive']},Users');
      csvData.writeln('Admin Users,${users['admins']},Users');
      csvData.writeln('New Users This Month,${users['newThisMonth']},Users');
      
      // Lesson metrics
      final lessons = stats['lessons'] as Map<String, dynamic>;
      csvData.writeln('Total Lessons,${lessons['total']},Lessons');
      csvData.writeln('Active Lessons,${lessons['active']},Lessons');
      csvData.writeln('Total Completions,${lessons['totalCompletions']},Lessons');
      
      // Quiz metrics
      final quizzes = stats['quizzes'] as Map<String, dynamic>;
      csvData.writeln('Total Quizzes,${quizzes['total']},Quizzes');
      csvData.writeln('Active Quizzes,${quizzes['active']},Quizzes');
      csvData.writeln('Total Attempts,${quizzes['totalAttempts']},Quizzes');
      csvData.writeln('Pass Rate,${quizzes['passRate'].toStringAsFixed(1)}%,Quizzes');
      
      return csvData.toString();
    } catch (e) {
      if (kDebugMode) print('❌ Error exporting analytics to CSV: $e');
      return 'Error,Could not export data,Error';
    }
  }
} 