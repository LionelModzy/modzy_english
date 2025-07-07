import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../models/vocab_model.dart';

class VocabularyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'vocabulary';

  /// Get all vocabulary words
  static Future<List<VocabularyModel>> getAllVocabulary() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('word')
          .get();

      return querySnapshot.docs
          .map((doc) => VocabularyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching vocabulary: $e');
      return [];
    }
  }

  /// Get vocabulary by lesson ID
  static Future<List<VocabularyModel>> getVocabularyByLessonId(String lessonId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('lessonIds', arrayContains: lessonId)
          .get();

      return querySnapshot.docs
          .map((doc) => VocabularyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching vocabulary for lesson: $e');
      return [];
    }
  }

  /// Get vocabulary by category
  static Future<List<VocabularyModel>> getVocabularyByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('word')
          .get();

      return querySnapshot.docs
          .map((doc) => VocabularyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching vocabulary by category: $e');
      return [];
    }
  }

  /// Search vocabulary words
  static Future<List<VocabularyModel>> searchVocabulary(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final allWords = querySnapshot.docs
          .map((doc) => VocabularyModel.fromFirestore(doc))
          .toList();

      // Client-side filtering for better search
      return allWords.where((word) {
        return word.word.toLowerCase().contains(query.toLowerCase()) ||
               word.meaning.toLowerCase().contains(query.toLowerCase()) ||
               word.pronunciation.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error searching vocabulary: $e');
      return [];
    }
  }

  /// Add or update vocabulary
  static Future<bool> saveVocabulary(VocabularyModel vocabulary) async {
    try {
      if (vocabulary.id.isEmpty) {
        // Add new vocabulary
        final docRef = await _firestore.collection(_collection).add(vocabulary.toMap());
        if (kDebugMode) print('✅ Added vocabulary: ${vocabulary.word} with ID: ${docRef.id}');
      } else {
        // Update existing vocabulary
        await _firestore.collection(_collection).doc(vocabulary.id).set(vocabulary.toMap());
        if (kDebugMode) print('✅ Updated vocabulary: ${vocabulary.word}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving vocabulary: $e');
      return false;
    }
  }

  /// Delete vocabulary
  static Future<bool> deleteVocabulary(String vocabularyId) async {
    try {
      await _firestore.collection(_collection).doc(vocabularyId).delete();
      if (kDebugMode) print('✅ Deleted vocabulary: $vocabularyId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting vocabulary: $e');
      return false;
    }
  }

  /// Get vocabulary statistics
  static Future<Map<String, int>> getVocabularyStats() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      final allWords = querySnapshot.docs
          .map((doc) => VocabularyModel.fromFirestore(doc))
          .toList();

      return {
        'total': allWords.length,
        'active': allWords.where((w) => w.isActive).length,
        'with_audio': allWords.where((w) => w.hasAudio).length,
        'with_images': allWords.where((w) => w.hasImage).length,
        'beginner': allWords.where((w) => w.difficultyLevel == 1).length,
        'elementary': allWords.where((w) => w.difficultyLevel == 2).length,
        'intermediate': allWords.where((w) => w.difficultyLevel == 3).length,
        'upper_intermediate': allWords.where((w) => w.difficultyLevel == 4).length,
        'advanced': allWords.where((w) => w.difficultyLevel == 5).length,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting vocabulary stats: $e');
      return {};
    }
  }

  /// Create vocabulary from lesson words
  static Future<bool> createVocabularyFromWords(
    List<String> words, 
    String lessonId, 
    String category,
    int difficultyLevel,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (String word in words) {
        if (word.trim().isEmpty) continue;
        
        final vocabularyModel = VocabularyModel(
          id: '',
          word: word.trim(),
          pronunciation: '', // To be filled manually
          meaning: '', // To be filled manually
          definition: null,
          examples: [],
          imageUrl: null,
          audioUrl: null,
          category: category,
          difficultyLevel: difficultyLevel,
          synonyms: [],
          antonyms: [],
          partOfSpeech: '',
          lessonIds: [lessonId], // Required parameter
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          metadata: {
            'auto_generated': true,
          },
        );
        
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, vocabularyModel.toMap());
      }
      
      await batch.commit();
      if (kDebugMode) print('✅ Created ${words.length} vocabulary entries');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating vocabulary from words: $e');
      return false;
    }
  }
} 