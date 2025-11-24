import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/challenge_exercise_model.dart';

class ChallengeExerciseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'challenge_exercises';

  /// Get current authenticated user ID
  static String? _getCurrentUserId() {
    final user = _auth.currentUser;
    return user?.uid;
  }

  /// Get all active challenge exercises
  static Future<List<ChallengeExerciseModel>> getAllChallengeExercises() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeExerciseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching challenge exercises: $e');
      return [];
    }
  }

  /// Get challenge exercises by type
  static Future<List<ChallengeExerciseModel>> getExercisesByType(String challengeType) async {
    try {
      // Try query with orderBy first (requires index)
      try {
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('challengeType', isEqualTo: challengeType)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs
            .map((doc) => ChallengeExerciseModel.fromFirestore(doc))
            .toList();
      } catch (e) {
        // If orderBy fails (missing index), try without orderBy
        if (kDebugMode) print('⚠️ Query with orderBy failed, trying without orderBy: $e');
        
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('challengeType', isEqualTo: challengeType)
            .where('isActive', isEqualTo: true)
            .get();

        final exercises = querySnapshot.docs
            .map((doc) => ChallengeExerciseModel.fromFirestore(doc))
            .toList();
        
        // Sort manually
        exercises.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return exercises;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching challenge exercises by type: $e');
      return [];
    }
  }

  /// Get a random challenge exercise by type
  static Future<ChallengeExerciseModel?> getRandomExerciseByType(String challengeType) async {
    try {
      if (kDebugMode) print('🔍 Getting random exercise for challengeType: $challengeType');
      
      final exercises = await getExercisesByType(challengeType);
      
      if (kDebugMode) {
        print('📦 Found ${exercises.length} exercises for type: $challengeType');
        if (exercises.isEmpty) {
          print('⚠️ No exercises found. Checking all active exercises...');
          final allActive = await getAllChallengeExercises();
          print('📊 Total active exercises: ${allActive.length}');
          if (allActive.isNotEmpty) {
            print('📋 Available challenge types:');
            final types = allActive.map((e) => e.challengeType).toSet();
            for (var type in types) {
              print('   - $type: ${allActive.where((e) => e.challengeType == type).length} exercises');
            }
          }
        }
      }
      
      if (exercises.isEmpty) return null;
      
      // Return a random exercise
      exercises.shuffle();
      return exercises.first;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting random challenge exercise: $e');
      return null;
    }
  }

  /// Get all challenge exercises for admin (both active and inactive)
  static Future<List<ChallengeExerciseModel>> getAllExercisesForAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeExerciseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching all challenge exercises: $e');
      return [];
    }
  }

  /// Get challenge exercise by ID
  static Future<ChallengeExerciseModel?> getExerciseById(String exerciseId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(exerciseId).get();
      if (!doc.exists) return null;
      return ChallengeExerciseModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) print('Error fetching challenge exercise: $e');
      return null;
    }
  }

  /// Create a new challenge exercise
  static Future<String?> createChallengeExercise(ChallengeExerciseModel exercise) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) print('❌ No authenticated user');
        return null;
      }
      
      final exerciseWithCreator = ChallengeExerciseModel(
        id: '',
        title: exercise.title,
        description: exercise.description,
        challengeType: exercise.challengeType,
        questions: exercise.questions,
        timeLimit: exercise.timeLimit,
        isActive: exercise.isActive,
        category: exercise.category,
        difficultyLevel: exercise.difficultyLevel,
        createdAt: exercise.createdAt,
        updatedAt: DateTime.now(),
        createdBy: userId,
        metadata: exercise.metadata,
      );
      
      final docRef = await _firestore.collection(_collection).add(exerciseWithCreator.toMap());
      if (kDebugMode) print('✅ Challenge exercise created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating challenge exercise: $e');
      return null;
    }
  }

  /// Update challenge exercise
  static Future<bool> updateChallengeExercise(ChallengeExerciseModel exercise) async {
    try {
      await _firestore.collection(_collection).doc(exercise.id).update(exercise.toMap());
      if (kDebugMode) print('✅ Challenge exercise updated: ${exercise.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating challenge exercise: $e');
      return false;
    }
  }

  /// Delete challenge exercise
  static Future<bool> deleteChallengeExercise(String exerciseId) async {
    try {
      await _firestore.collection(_collection).doc(exerciseId).delete();
      if (kDebugMode) print('✅ Challenge exercise deleted: $exerciseId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting challenge exercise: $e');
      return false;
    }
  }

  /// Toggle active status
  static Future<bool> toggleActiveStatus(String exerciseId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(exerciseId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) print('✅ Challenge exercise status updated: $exerciseId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating challenge exercise status: $e');
      return false;
    }
  }
}

