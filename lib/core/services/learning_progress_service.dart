import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LearningProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Progress tracking for lessons
  static Future<bool> trackLessonProgress({
    required String lessonId,
    required int timeSpent, // in seconds
    required double completionPercentage,
    required Map<String, dynamic> details,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final progressData = {
        'lessonId': lessonId,
        'userId': userId,
        'timeSpent': timeSpent,
        'completionPercentage': completionPercentage,
        'details': details,
        'lastStudied': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Use merge to update existing progress or create new
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .doc(lessonId)
          .set(progressData, SetOptions(merge: true));

      // Update global user stats
      await _updateUserStats(userId);

      return true;
    } catch (e) {
      if (kDebugMode) print('Error tracking lesson progress: $e');
      return false;
    }
  }
  
  // Nuevo método: Track progress for specific lesson section media
  static Future<bool> trackLessonSectionMediaProgress({
    required String lessonId,
    required int sectionIndex,
    required String mediaType, // 'video' or 'audio'
    required int positionInSeconds,
    required int durationInSeconds,
    required double progress, // 0.0 - 1.0
    bool completed = false,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      if (kDebugMode) {
        print('Saving media progress:');
        print('Lesson: $lessonId, Section: $sectionIndex');
        print('Position: $positionInSeconds sec, Progress: ${(progress * 100).toStringAsFixed(1)}%');
      }
      
      final mediaProgressData = {
        'lessonId': lessonId,
        'sectionIndex': sectionIndex,
        'mediaType': mediaType,
        'positionInSeconds': positionInSeconds,
        'durationInSeconds': durationInSeconds,
        'progress': progress,
        'completed': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Generate a document ID for the section media progress
      final docId = '${lessonId}_section_${sectionIndex}';
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lesson_media_progress')
          .doc(docId)
          .set(mediaProgressData, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      if (kDebugMode) print('Error tracking lesson section media progress: $e');
      return false;
    }
  }
  
  // Nuevo método: Get progress for specific lesson section media
  static Future<Map<String, dynamic>?> getLessonSectionMediaProgress({
    required String lessonId,
    required int sectionIndex,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;
      
      final docId = '${lessonId}_section_${sectionIndex}';
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lesson_media_progress')
          .doc(docId)
          .get();
      
      if (doc.exists) {
        if (kDebugMode) {
          print('Retrieved media progress for section $sectionIndex: ${doc.data()}');
        }
        return doc.data();
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting lesson section media progress: $e');
      return null;
    }
  }

  // Progress tracking for vocabulary practice
  static Future<bool> trackVocabularyProgress({
    required String vocabularyId,
    required int correctAnswers,
    required int totalQuestions,
    required String practiceType, // flashcard, multiple_choice, etc.
    required int timeSpent,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final progressData = {
        'vocabularyId': vocabularyId,
        'userId': userId,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'accuracy': (correctAnswers / totalQuestions * 100).round(),
        'practiceType': practiceType,
        'timeSpent': timeSpent,
        'practicedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add to practice history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary_progress')
          .add(progressData);

      // Update vocabulary mastery level
      await _updateVocabularyMastery(userId, vocabularyId, correctAnswers, totalQuestions);

      return true;
    } catch (e) {
      if (kDebugMode) print('Error tracking vocabulary progress: $e');
      return false;
    }
  }

  // Progress tracking for general activities
  static Future<bool> trackGeneralProgress({
    required String activityType,
    required Map<String, dynamic> details,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ No authenticated user for progress tracking');
        return false;
      }

      print('📊 Tracking progress: $activityType');
      print('👤 User ID: $userId');

      final progressData = {
        'userId': userId,
        'activityType': activityType,
        'details': details,
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add to general progress history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('general_progress')
          .add(progressData);

      print('✅ Progress tracked successfully');
      return true;
    } catch (e) {
      print('❌ Error tracking general progress: $e');
      return false;
    }
  }

  // Get user's lesson progress
  static Future<Map<String, dynamic>?> getLessonProgress(String lessonId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .doc(lessonId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting lesson progress: $e');
      return null;
    }
  }

  // Get vocabulary mastery data
  static Future<Map<String, dynamic>?> getVocabularyMastery(String vocabularyId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary_mastery')
          .doc(vocabularyId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting vocabulary mastery: $e');
      return null;
    }
  }

  // Get learning statistics
  static Future<Map<String, dynamic>> getLearningStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      // Get lesson progress stats
      final lessonProgressQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .get();

      final completedLessons = lessonProgressQuery.docs
          .where((doc) => (doc.data()['completionPercentage'] ?? 0) >= 100)
          .length;

      final inProgressLessons = lessonProgressQuery.docs
          .where((doc) {
            final completion = doc.data()['completionPercentage'] ?? 0;
            return completion > 0 && completion < 100;
          })
          .length;

      // Get vocabulary practice stats
      final vocabProgressQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary_progress')
          .orderBy('practicedAt', descending: true)
          .limit(100)
          .get();

      final totalPractices = vocabProgressQuery.docs.length;
      final totalCorrect = vocabProgressQuery.docs
          .fold<int>(0, (total, doc) => total + ((doc.data()['correctAnswers'] ?? 0) as int));
      final totalQuestions = vocabProgressQuery.docs
          .fold<int>(0, (total, doc) => total + ((doc.data()['totalQuestions'] ?? 0) as int));

      final averageAccuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions * 100).round() : 0;

      // Get streak data
      final streakData = await _getStudyStreak(userId);

      // Get total study time
      final totalStudyTime = await _getTotalStudyTime(userId);

      return {
        'completedLessons': completedLessons,
        'inProgressLessons': inProgressLessons,
        'totalLessons': lessonProgressQuery.docs.length,
        'totalPractices': totalPractices,
        'averageAccuracy': averageAccuracy,
        'currentStreak': streakData['currentStreak'] ?? 0,
        'bestStreak': streakData['bestStreak'] ?? 0,
        'totalStudyTime': totalStudyTime, // in minutes
        'lastStudied': streakData['lastStudied'],
      };
    } catch (e) {
      if (kDebugMode) print('Error getting learning stats: $e');
      return {};
    }
  }

  // Get recent learning history (3 latest from GENERAL PROGRESS only to avoid duplicates)
  static Future<List<Map<String, dynamic>>> getRecentHistory({int limit = 3}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final List<Map<String, dynamic>> allActivities = [];

      // Get recent general progress (vocabulary practice sessions)
      final generalProgress = await _firestore
          .collection('users')
          .doc(userId)
          .collection('general_progress')
          .orderBy('completedAt', descending: true)
          .limit(limit * 2)
          .get();

      for (var doc in generalProgress.docs) {
        final data = doc.data();
        final details = data['details'] ?? {};
        
        if (data['activityType'] == 'vocabulary_practice') {
          allActivities.add({
            'type': 'vocabulary',
            'title': 'Luyện từ vựng',
            'subtitle': _getPracticeTypeDisplayName(details['mode'] ?? 'flashcard'),
            'accuracy': details['accuracy'] ?? 0,
            'completion': details['accuracy'] ?? 0,
            'timestamp': data['completedAt'],
            'icon': 'quiz',
            'color': 'purple',
            'details': {
              'correctAnswers': details['correctAnswers'] ?? 0,
              'totalQuestions': details['vocabulariesCount'] ?? 0,
              'timeSpent': details['timeSpent'] ?? 0,
            }
          });
        }
      }

      // Get recent lesson progress
      final lessonProgress = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .orderBy('lastStudied', descending: true)
          .limit(limit)
          .get();

      for (var doc in lessonProgress.docs) {
        final data = doc.data();
        allActivities.add({
          'type': 'lesson',
          'title': data['lessonTitle'] ?? 'Bài học',
          'subtitle': 'Bài học hoàn thành',
          'completion': data['completionPercentage'] ?? 0,
          'accuracy': data['completionPercentage'] ?? 0,
          'timestamp': data['lastStudied'],
          'icon': 'book',
          'color': 'blue',
          'details': {
            'timeSpent': data['timeSpent'] ?? 0,
            'lessonId': data['lessonId'],
          }
        });
      }

      // Sort all activities by timestamp and take the most recent ones
      allActivities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return allActivities.take(limit).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting recent history: $e');
      return [];
    }
  }

  // Helper method to get display name for practice type
  static String _getPracticeTypeDisplayName(String practiceType) {
    switch (practiceType) {
      case 'flashcard':
        return 'Thẻ từ';
      case 'multiple_choice':
        return 'Trắc nghiệm';
      case 'typing':
        return 'Điền từ';
      case 'listening':
        return 'Nghe & chọn';
      default:
        return 'Luyện tập';
    }
  }

  // Private helper methods
  static Future<void> _updateUserStats(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      await userRef.update({
        'lastActivity': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Error updating user stats: $e');
    }
  }

  static Future<void> _updateVocabularyMastery(
    String userId,
    String vocabularyId,
    int correctAnswers,
    int totalQuestions,
  ) async {
    try {
      final masteryRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary_mastery')
          .doc(vocabularyId);

      final doc = await masteryRef.get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final oldCorrect = data['totalCorrect'] ?? 0;
        final oldTotal = data['totalQuestions'] ?? 0;
        final newCorrect = oldCorrect + correctAnswers;
        final newTotal = oldTotal + totalQuestions;
        final newMastery = (newCorrect / newTotal * 100).round();

        await masteryRef.update({
          'totalCorrect': newCorrect,
          'totalQuestions': newTotal,
          'masteryLevel': newMastery,
          'practiceCount': FieldValue.increment(1),
          'lastPracticed': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final mastery = (correctAnswers / totalQuestions * 100).round();
        await masteryRef.set({
          'vocabularyId': vocabularyId,
          'totalCorrect': correctAnswers,
          'totalQuestions': totalQuestions,
          'masteryLevel': mastery,
          'practiceCount': 1,
          'firstPracticed': FieldValue.serverTimestamp(),
          'lastPracticed': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error updating vocabulary mastery: $e');
    }
  }

  static Future<Map<String, dynamic>> _getStudyStreak(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'currentStreak': data['currentStreak'] ?? 0,
          'bestStreak': data['bestStreak'] ?? 0,
          'lastStudied': data['lastActivity'],
        };
      }
      
      return {
        'currentStreak': 0,
        'bestStreak': 0,
        'lastStudied': null,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting study streak: $e');
      return {};
    }
  }

  static Future<int> _getTotalStudyTime(String userId) async {
    try {
      // Sum time from lesson progress
      final lessonProgress = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .get();

      int lessonTime = 0;
      for (var doc in lessonProgress.docs) {
        lessonTime += (doc.data()['timeSpent'] ?? 0) as int;
      }

      // Sum time from vocabulary practice
      final vocabProgress = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary_progress')
          .get();

      int vocabTime = 0;
      for (var doc in vocabProgress.docs) {
        vocabTime += (doc.data()['timeSpent'] ?? 0) as int;
      }

      // Return total time in minutes
      return ((lessonTime + vocabTime) / 60).round();
    } catch (e) {
      if (kDebugMode) print('Error getting total study time: $e');
      return 0;
    }
  }

  // Update daily streak
  static Future<void> updateDailyStreak() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final lastActivity = data['lastActivity'] as Timestamp?;
      final currentStreak = data['currentStreak'] ?? 0;
      final bestStreak = data['bestStreak'] ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastActivity != null) {
        final lastActivityDate = lastActivity.toDate();
        final lastDate = DateTime(lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);

        final daysDifference = today.difference(lastDate).inDays;

        if (daysDifference == 1) {
          // Consecutive day - increment streak
          final newStreak = currentStreak + 1;
          await userRef.update({
            'currentStreak': newStreak,
            'bestStreak': newStreak > bestStreak ? newStreak : bestStreak,
            'lastActivity': FieldValue.serverTimestamp(),
          });
        } else if (daysDifference > 1) {
          // Streak broken - reset to 1
          await userRef.update({
            'currentStreak': 1,
            'lastActivity': FieldValue.serverTimestamp(),
          });
        }
        // Same day - no update needed
      } else {
        // First time - start streak
        await userRef.update({
          'currentStreak': 1,
          'bestStreak': 1,
          'lastActivity': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error updating daily streak: $e');
    }
  }
} 