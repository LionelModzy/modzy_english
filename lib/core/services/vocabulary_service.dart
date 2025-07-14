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

  /// Check if word already exists (case insensitive)
  static Future<VocabularyModel?> checkWordExists(String word) async {
    try {
      final cleanWord = word.toLowerCase().trim();
      
      // First try exact match (for most cases)
      final exactQuery = await _firestore
          .collection(_collection)
          .where('word', isEqualTo: word.trim())
          .limit(1)
          .get();
      
      if (exactQuery.docs.isNotEmpty) {
        return VocabularyModel.fromFirestore(exactQuery.docs.first);
      }
      
      // If no exact match, try case-insensitive search with a smaller dataset
      // Use a range query to limit the dataset
      final rangeQuery = await _firestore
          .collection(_collection)
          .where('word', isGreaterThanOrEqualTo: cleanWord)
          .where('word', isLessThan: cleanWord + '\uf8ff')
          .limit(50)
          .get();
      
      for (var doc in rangeQuery.docs) {
        final vocab = VocabularyModel.fromFirestore(doc);
        if (vocab.word.toLowerCase() == cleanWord) {
          return vocab;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error checking word existence: $e');
      // Fallback to original method for backward compatibility
      try {
        final querySnapshot = await _firestore
            .collection(_collection)
            .get();

        final allWords = querySnapshot.docs
            .map((doc) => VocabularyModel.fromFirestore(doc))
            .toList();

        // Check case-insensitive
        for (var vocab in allWords) {
          if (vocab.word.toLowerCase() == word.toLowerCase().trim()) {
            return vocab;
          }
        }
      } catch (fallbackError) {
        if (kDebugMode) print('❌ Fallback check also failed: $fallbackError');
      }
      return null;
    }
  }

  /// Add or update vocabulary with duplicate check
  static Future<Map<String, dynamic>> saveVocabulary(VocabularyModel vocabulary) async {
    try {
      if (vocabulary.id.isEmpty) {
        // Check for duplicates before adding
        final existingWord = await checkWordExists(vocabulary.word);
        if (existingWord != null) {
          // Double-check: ensure it's not a false positive by checking if the words are exactly the same
          if (existingWord.word.toLowerCase().trim() == vocabulary.word.toLowerCase().trim() &&
              existingWord.meaning.isNotEmpty) {
            return {
              'success': false,
              'message': 'Từ "${vocabulary.word}" đã tồn tại trong hệ thống',
              'existingWord': existingWord,
            };
          }
        }
        
        // Add new vocabulary with unique ID check
        try {
          final docRef = _firestore.collection(_collection).doc();
          final vocabularyWithId = VocabularyModel(
            id: docRef.id,
            word: vocabulary.word,
            pronunciation: vocabulary.pronunciation,
            meaning: vocabulary.meaning,
            definition: vocabulary.definition,
            examples: vocabulary.examples,
            imageUrl: vocabulary.imageUrl,
            audioUrl: vocabulary.audioUrl,
            category: vocabulary.category,
            difficultyLevel: vocabulary.difficultyLevel,
            synonyms: vocabulary.synonyms,
            antonyms: vocabulary.antonyms,
            partOfSpeech: vocabulary.partOfSpeech,
            lessonIds: vocabulary.lessonIds,
            createdAt: vocabulary.createdAt,
            updatedAt: DateTime.now(),
            isActive: vocabulary.isActive,
            usageCount: vocabulary.usageCount,
            metadata: vocabulary.metadata,
          );
          
          await docRef.set(vocabularyWithId.toMap());
          if (kDebugMode) print('✅ Added vocabulary: ${vocabulary.word} with ID: ${docRef.id}');
          
          return {
            'success': true,
            'message': 'Đã thêm từ vựng "${vocabulary.word}" thành công',
            'id': docRef.id,
          };
        } catch (addError) {
          if (kDebugMode) print('❌ Error adding vocabulary: $addError');
          throw addError;
        }
      } else {
        // Update existing vocabulary
        final updatedVocabulary = VocabularyModel(
          id: vocabulary.id,
          word: vocabulary.word,
          pronunciation: vocabulary.pronunciation,
          meaning: vocabulary.meaning,
          definition: vocabulary.definition,
          examples: vocabulary.examples,
          imageUrl: vocabulary.imageUrl,
          audioUrl: vocabulary.audioUrl,
          category: vocabulary.category,
          difficultyLevel: vocabulary.difficultyLevel,
          synonyms: vocabulary.synonyms,
          antonyms: vocabulary.antonyms,
          partOfSpeech: vocabulary.partOfSpeech,
          lessonIds: vocabulary.lessonIds,
          createdAt: vocabulary.createdAt,
          updatedAt: DateTime.now(),
          isActive: vocabulary.isActive,
          usageCount: vocabulary.usageCount,
          metadata: vocabulary.metadata,
        );
        
        await _firestore.collection(_collection).doc(vocabulary.id).set(updatedVocabulary.toMap());
        if (kDebugMode) print('✅ Updated vocabulary: ${vocabulary.word}');
        
        return {
          'success': true,
          'message': 'Đã cập nhật từ vựng "${vocabulary.word}" thành công',
          'id': vocabulary.id,
        };
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error saving vocabulary: $e');
      return {
        'success': false,
        'message': 'Lỗi lưu từ vựng: $e',
      };
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

  static Future<List<VocabularyModel>> getVocabulariesByCategory(String category, {int? limit}) async {
    try {
      Query query = _firestore
          .collection('vocabulary')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return VocabularyModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting vocabularies by category: $e');
      if (e.toString().contains('failed-precondition')) {
        print('Missing index for vocabulary category query. Creating fallback query...');
        // Fallback to simple query without ordering
        try {
          final snapshot = await _firestore
              .collection('vocabulary')
              .where('category', isEqualTo: category)
              .get();
          
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return VocabularyModel.fromMap(data);
          }).toList();
          
          // Sort manually
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          if (limit != null && docs.length > limit) {
            return docs.take(limit).toList();
          }
          
          return docs;
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
        }
      }
      return [];
    }
  }
} 