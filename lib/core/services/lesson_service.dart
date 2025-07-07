import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/lesson_model.dart';

class LessonService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'lessons';

  // Create a new lesson
  static Future<String> createLesson(LessonModel lesson) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(lesson.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create lesson: $e');
    }
  }

  // Update an existing lesson
  static Future<void> updateLesson(String lessonId, LessonModel lesson) async {
    try {
      await _firestore.collection(_collection).doc(lessonId).update(lesson.toMap());
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  // Delete a lesson
  static Future<void> deleteLesson(String lessonId) async {
    try {
      await _firestore.collection(_collection).doc(lessonId).delete();
    } catch (e) {
      throw Exception('Failed to delete lesson: $e');
    }
  }

  // Get all lessons
  static Future<List<LessonModel>> getAllLessons() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('order')
          .get();
      
      return snapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch lessons: $e');
    }
  }

  // Get lessons by category
  static Future<List<LessonModel>> getLessonsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      
      return snapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch lessons by category: $e');
    }
  }

  // Get lesson by ID
  static Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(lessonId).get();
      if (doc.exists) {
        return LessonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch lesson: $e');
    }
  }

  // Toggle lesson active status
  static Future<void> toggleLessonStatus(String lessonId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(lessonId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle lesson status: $e');
    }
  }

  // Toggle premium status
  static Future<void> togglePremiumStatus(String lessonId, bool isPremium) async {
    try {
      await _firestore.collection(_collection).doc(lessonId).update({
        'isPremium': isPremium,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle premium status: $e');
    }
  }

  // Search lessons
  static Future<List<LessonModel>> searchLessons(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .where((lesson) => 
              lesson.title.toLowerCase().contains(query.toLowerCase()) ||
              lesson.description.toLowerCase().contains(query.toLowerCase()) ||
              lesson.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      throw Exception('Failed to search lessons: $e');
    }
  }

  // Get lesson analytics
  static Future<Map<String, dynamic>> getLessonAnalytics(String lessonId) async {
    try {
      // This would connect to a user progress collection
      QuerySnapshot progressSnapshot = await _firestore
          .collection('user_progress')
          .where('lessonId', isEqualTo: lessonId)
          .get();

      int totalViews = progressSnapshot.docs.length;
      int completions = progressSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['completed'] == true)
          .length;
      
      double completionRate = totalViews > 0 ? (completions / totalViews) * 100 : 0;

      return {
        'totalViews': totalViews,
        'completions': completions,
        'completionRate': completionRate,
        'averageScore': _calculateAverageScore(progressSnapshot.docs),
      };
    } catch (e) {
      throw Exception('Failed to fetch lesson analytics: $e');
    }
  }

  static double _calculateAverageScore(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0.0;
    
    double totalScore = 0;
    int validScores = 0;
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['score'] != null) {
        totalScore += (data['score'] as num).toDouble();
        validScores++;
      }
    }
    
    return validScores > 0 ? totalScore / validScores : 0.0;
  }
} 