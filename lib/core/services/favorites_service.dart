import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vocab_model.dart';
import '../../models/lesson_model.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add vocabulary to favorites
  static Future<bool> addVocabularyToFavorites(String vocabularyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('vocabulary_$vocabularyId')
          .set({
        'type': 'vocabulary',
        'itemId': vocabularyId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding vocabulary to favorites: $e');
      if (e.toString().contains('permission-denied')) {
        print('Permission denied: User may need to re-authenticate');
      }
      return false;
    }
  }

  // Remove vocabulary from favorites
  static Future<bool> removeVocabularyFromFavorites(String vocabularyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('vocabulary_$vocabularyId')
          .delete();

      return true;
    } catch (e) {
      print('Error removing vocabulary from favorites: $e');
      return false;
    }
  }

  // Add lesson to favorites
  static Future<bool> addLessonToFavorites(String lessonId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('lesson_$lessonId')
          .set({
        'type': 'lesson',
        'itemId': lessonId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding lesson to favorites: $e');
      return false;
    }
  }

  // Remove lesson from favorites
  static Future<bool> removeLessonFromFavorites(String lessonId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('lesson_$lessonId')
          .delete();

      return true;
    } catch (e) {
      print('Error removing lesson from favorites: $e');
      return false;
    }
  }

  // Check if vocabulary is in favorites
  static Future<bool> isVocabularyInFavorites(String vocabularyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('vocabulary_$vocabularyId')
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking vocabulary favorites: $e');
      return false;
    }
  }

  // Check if lesson is in favorites
  static Future<bool> isLessonInFavorites(String lessonId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('lesson_$lessonId')
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking lesson favorites: $e');
      return false;
    }
  }

  // Get favorite vocabularies
  static Future<List<VocabularyModel>> getFavoriteVocabularies() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .where('type', isEqualTo: 'vocabulary')
          .orderBy('addedAt', descending: true)
          .get();

      List<VocabularyModel> favoriteVocabularies = [];

      for (var doc in favoritesSnapshot.docs) {
        String vocabularyId = doc.data()['itemId'];
        
        try {
          final vocabDoc = await _firestore
              .collection('vocabulary')
              .doc(vocabularyId)
              .get();
          
          if (vocabDoc.exists) {
            favoriteVocabularies.add(VocabularyModel.fromFirestore(vocabDoc));
          }
        } catch (e) {
          print('Error loading vocabulary $vocabularyId: $e');
        }
      }

      return favoriteVocabularies;
    } catch (e) {
      print('Error getting favorite vocabularies: $e');
      return [];
    }
  }

  // Get favorite lessons
  static Future<List<LessonModel>> getFavoriteLessons() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .where('type', isEqualTo: 'lesson')
          .orderBy('addedAt', descending: true)
          .get();

      List<LessonModel> favoriteLessons = [];

      for (var doc in favoritesSnapshot.docs) {
        String lessonId = doc.data()['itemId'];
        
        try {
          final lessonDoc = await _firestore
              .collection('lessons')
              .doc(lessonId)
              .get();
          
          if (lessonDoc.exists) {
            favoriteLessons.add(LessonModel.fromFirestore(lessonDoc));
          }
        } catch (e) {
          print('Error loading lesson $lessonId: $e');
        }
      }

      return favoriteLessons;
    } catch (e) {
      print('Error getting favorite lessons: $e');
      return [];
    }
  }

  // Toggle vocabulary favorite status
  static Future<bool> toggleVocabularyFavorite(String vocabularyId) async {
    final isFavorite = await isVocabularyInFavorites(vocabularyId);
    
    if (isFavorite) {
      return await removeVocabularyFromFavorites(vocabularyId);
    } else {
      return await addVocabularyToFavorites(vocabularyId);
    }
  }

  // Toggle lesson favorite status
  static Future<bool> toggleLessonFavorite(String lessonId) async {
    final isFavorite = await isLessonInFavorites(lessonId);
    
    if (isFavorite) {
      return await removeLessonFromFavorites(lessonId);
    } else {
      return await addLessonToFavorites(lessonId);
    }
  }

  // Get favorites count
  static Future<Map<String, int>> getFavoritesCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'vocabulary': 0, 'lesson': 0};

      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      int vocabularyCount = 0;
      int lessonCount = 0;

      for (var doc in favoritesSnapshot.docs) {
        final type = doc.data()['type'];
        if (type == 'vocabulary') {
          vocabularyCount++;
        } else if (type == 'lesson') {
          lessonCount++;
        }
      }

      return {
        'vocabulary': vocabularyCount,
        'lesson': lessonCount,
      };
    } catch (e) {
      print('Error getting favorites count: $e');
      return {'vocabulary': 0, 'lesson': 0};
    }
  }
} 