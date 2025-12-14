import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/vocab_model.dart';
import '../../models/mini_game_model.dart';
import 'vocabulary_service.dart';
import 'mini_game_service.dart';

class SampleDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create sample vocabulary data for mini games
  static Future<void> createSampleVocabulary() async {
    try {
      if (kDebugMode) print('🎯 Creating sample vocabulary data...');
      
      final sampleVocabulary = [
        // Basic words for beginners
        VocabularyModel(
          id: '',
          word: 'Hello',
          pronunciation: '/həˈloʊ/',
          meaning: 'Xin chào',
          definition: 'A greeting used when meeting someone',
          examples: ['Hello, how are you?', 'Hello, nice to meet you!'],
          imageUrl: null,
          audioUrl: null,
          category: 'Greetings',
          difficultyLevel: 1,
          synonyms: ['Hi', 'Hey'],
          antonyms: [],
          partOfSpeech: 'interjection',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Good',
          pronunciation: '/ɡʊd/',
          meaning: 'Tốt',
          definition: 'Having the required qualities or of a high standard',
          examples: ['This is a good book', 'She is a good student'],
          imageUrl: null,
          audioUrl: null,
          category: 'Adjectives',
          difficultyLevel: 1,
          synonyms: ['Great', 'Excellent', 'Fine'],
          antonyms: ['Bad', 'Poor'],
          partOfSpeech: 'adjective',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Book',
          pronunciation: '/bʊk/',
          meaning: 'Quyển sách',
          definition: 'A written or printed work consisting of pages',
          examples: ['I read a book yesterday', 'This book is interesting'],
          imageUrl: null,
          audioUrl: null,
          category: 'Objects',
          difficultyLevel: 1,
          synonyms: ['Novel', 'Textbook'],
          antonyms: [],
          partOfSpeech: 'noun',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Cat',
          pronunciation: '/kæt/',
          meaning: 'Con mèo',
          definition: 'A small domesticated carnivorous mammal',
          examples: ['My cat is sleeping', 'The cat is playing'],
          imageUrl: null,
          audioUrl: null,
          category: 'Animals',
          difficultyLevel: 1,
          synonyms: ['Feline'],
          antonyms: [],
          partOfSpeech: 'noun',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Dog',
          pronunciation: '/dɔːɡ/',
          meaning: 'Con chó',
          definition: 'A domesticated carnivorous mammal',
          examples: ['The dog is barking', 'I love my dog'],
          imageUrl: null,
          audioUrl: null,
          category: 'Animals',
          difficultyLevel: 1,
          synonyms: ['Canine', 'Puppy'],
          antonyms: [],
          partOfSpeech: 'noun',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'House',
          pronunciation: '/haʊs/',
          meaning: 'Ngôi nhà',
          definition: 'A building for human habitation',
          examples: ['I live in a big house', 'This house is beautiful'],
          imageUrl: null,
          audioUrl: null,
          category: 'Places',
          difficultyLevel: 1,
          synonyms: ['Home', 'Residence'],
          antonyms: [],
          partOfSpeech: 'noun',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Water',
          pronunciation: '/ˈwɔːtər/',
          meaning: 'Nước',
          definition: 'A colorless, transparent, odorless liquid',
          examples: ['I drink water every day', 'Water is essential for life'],
          imageUrl: null,
          audioUrl: null,
          category: 'Nature',
          difficultyLevel: 1,
          synonyms: ['H2O', 'Liquid'],
          antonyms: [],
          partOfSpeech: 'noun',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Tree',
          pronunciation: '/triː/',
          meaning: 'Cây',
          definition: 'A woody perennial plant with a trunk',
          examples: ['The tree is tall', 'I planted a tree'],
          imageUrl: null,
          audioUrl: null,
          category: 'Nature',
          difficultyLevel: 1,
          synonyms: ['Plant', 'Wood'],
          antonyms: [],
          partOfSpeech: 'noun',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Red',
          pronunciation: '/red/',
          meaning: 'Màu đỏ',
          definition: 'A color at the end of the spectrum',
          examples: ['The apple is red', 'I like red color'],
          imageUrl: null,
          audioUrl: null,
          category: 'Colors',
          difficultyLevel: 1,
          synonyms: ['Crimson', 'Scarlet'],
          antonyms: [],
          partOfSpeech: 'adjective',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Blue',
          pronunciation: '/bluː/',
          meaning: 'Màu xanh dương',
          definition: 'A color intermediate between green and violet',
          examples: ['The sky is blue', 'I have blue eyes'],
          imageUrl: null,
          audioUrl: null,
          category: 'Colors',
          difficultyLevel: 1,
          synonyms: ['Azure', 'Navy'],
          antonyms: [],
          partOfSpeech: 'adjective',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Eat',
          pronunciation: '/iːt/',
          meaning: 'Ăn',
          definition: 'To put food into the mouth and swallow it',
          examples: ['I eat breakfast every day', 'Let\'s eat dinner'],
          imageUrl: null,
          audioUrl: null,
          category: 'Actions',
          difficultyLevel: 1,
          synonyms: ['Consume', 'Devour'],
          antonyms: [],
          partOfSpeech: 'verb',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
        VocabularyModel(
          id: '',
          word: 'Run',
          pronunciation: '/rʌn/',
          meaning: 'Chạy',
          definition: 'To move quickly on foot',
          examples: ['I run every morning', 'He runs fast'],
          imageUrl: null,
          audioUrl: null,
          category: 'Actions',
          difficultyLevel: 1,
          synonyms: ['Jog', 'Sprint'],
          antonyms: ['Walk'],
          partOfSpeech: 'verb',
          lessonIds: ['sample_lesson_1'],
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          usageCount: 0,
          createdBy: 'system',
          metadata: {'sampleData': true},
        ),
      ];

      // Save vocabulary to Firestore
      final batch = _firestore.batch();
      final vocabularyIds = <String>[];
      
      for (var vocab in sampleVocabulary) {
        final docRef = _firestore.collection('vocabulary').doc();
        final vocabWithId = vocab.copyWith(id: docRef.id);
        batch.set(docRef, vocabWithId.toMap());
        vocabularyIds.add(docRef.id);
      }
      
      await batch.commit();
      if (kDebugMode) print('✅ Created ${sampleVocabulary.length} sample vocabulary entries');
      
      // Create sample mini games
      await _createSampleMiniGames(vocabularyIds);
      
    } catch (e) {
      if (kDebugMode) print('❌ Error creating sample vocabulary: $e');
    }
  }

  /// Create sample mini games
  static Future<void> _createSampleMiniGames(List<String> vocabularyIds) async {
    try {
      if (kDebugMode) print('🎮 Creating sample mini games...');
      
      // Get vocabulary words to filter by content
      final allVocabularies = await VocabularyService.getAllVocabulary();
      final sampleVocabularies = allVocabularies.where((v) => v.metadata['sampleData'] == true).toList();
      
      final catDogIds = sampleVocabularies
          .where((v) => ['Cat', 'Dog'].contains(v.word))
          .map((v) => v.id)
          .toList();
      
      final colorIds = sampleVocabularies
          .where((v) => ['Red', 'Blue'].contains(v.word))
          .map((v) => v.id)
          .toList();
      
      final sampleGames = [
        MiniGameModel(
          id: '',
          gameType: 'word_match',
          title: 'Basic Words Match',
          description: 'Match English words with their Vietnamese meanings',
          difficultyLevel: 1,
          category: 'Vocabulary',
          vocabularyIds: vocabularyIds.take(8).toList(),
          gameData: {
            'instructions': 'Match the English word with its Vietnamese meaning',
            'timeLimit': 60,
            'pointsPerMatch': 10,
          },
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          createdBy: 'system',
          playCount: 0,
          averageScore: 0.0,
          metadata: {'sampleData': true, 'autoGenerated': true},
        ),
        MiniGameModel(
          id: '',
          gameType: 'word_scramble',
          title: 'Animal Word Scramble',
          description: 'Unscramble the letters to form animal names',
          difficultyLevel: 1,
          category: 'Vocabulary',
          vocabularyIds: catDogIds.isNotEmpty ? catDogIds : vocabularyIds.take(4).toList(),
          gameData: {
            'instructions': 'Unscramble the letters to form the word',
            'timeLimit': 90,
            'pointsPerWord': 15,
          },
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          createdBy: 'system',
          playCount: 0,
          averageScore: 0.0,
          metadata: {'sampleData': true, 'autoGenerated': true},
        ),
        MiniGameModel(
          id: '',
          gameType: 'word_search',
          title: 'Color Word Search',
          description: 'Find color words hidden in the puzzle',
          difficultyLevel: 1,
          category: 'Vocabulary',
          vocabularyIds: colorIds.isNotEmpty ? colorIds : vocabularyIds.take(4).toList(),
          gameData: {
            'instructions': 'Find all the color words in the puzzle',
            'timeLimit': 120,
            'pointsPerWord': 20,
          },
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          createdBy: 'system',
          playCount: 0,
          averageScore: 0.0,
          metadata: {'sampleData': true, 'autoGenerated': true},
        ),
      ];

      // Save mini games to Firestore
      for (var game in sampleGames) {
        await MiniGameService.saveGame(game);
      }
      
      if (kDebugMode) print('✅ Created ${sampleGames.length} sample mini games');
      
    } catch (e) {
      if (kDebugMode) print('❌ Error creating sample mini games: $e');
    }
  }

  /// Check if sample data exists
  static Future<bool> hasSampleData() async {
    try {
      final vocabQuery = await _firestore
          .collection('vocabulary')
          .where('metadata.sampleData', isEqualTo: true)
          .limit(1)
          .get();
      
      final gameQuery = await _firestore
          .collection('mini_games')
          .where('metadata.sampleData', isEqualTo: true)
          .limit(1)
          .get();
      
      return vocabQuery.docs.isNotEmpty && gameQuery.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Error checking sample data: $e');
      // If we can't check, assume data exists to avoid permission errors
      return true;
    }
  }

  /// Initialize sample data if not exists
  static Future<void> initializeSampleData() async {
    try {
      // Check if current user is admin
      final isAdmin = await _isCurrentUserAdmin();
      if (!isAdmin) {
        if (kDebugMode) print('⚠️ Only admin can initialize sample data');
        return;
      }
      
      final hasData = await hasSampleData();
      if (!hasData) {
        if (kDebugMode) print('🚀 Initializing sample data...');
        await createSampleVocabulary();
        if (kDebugMode) print('✅ Sample data initialization complete');
      } else {
        if (kDebugMode) print('📊 Sample data already exists');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error initializing sample data: $e');
    }
  }

  /// Check if current user is admin
  static Future<bool> _isCurrentUserAdmin() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['role'] == 'admin';
    } catch (e) {
      if (kDebugMode) print('Error checking admin status: $e');
      return false;
    }
  }
}