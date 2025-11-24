import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/mini_game_model.dart';
import '../../models/vocab_model.dart';
import 'vocabulary_service.dart';

class MiniGameService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _gamesCollection = 'mini_games';
  static const String _scoresCollection = 'game_scores';

  /// Get all mini games
  static Future<List<MiniGameModel>> getAllGames() async {
    try {
      final querySnapshot = await _firestore
          .collection(_gamesCollection) 
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MiniGameModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching mini games: $e');
      return [];
    }
  }

  /// Get games by type
  static Future<List<MiniGameModel>> getGamesByType(String gameType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_gamesCollection)
          .where('gameType', isEqualTo: gameType)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MiniGameModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching games by type: $e');
      return [];
    }
  }

  /// Get games by difficulty
  static Future<List<MiniGameModel>> getGamesByDifficulty(int difficultyLevel) async {
    try {
      final querySnapshot = await _firestore
          .collection(_gamesCollection)
          .where('difficultyLevel', isEqualTo: difficultyLevel)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MiniGameModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching games by difficulty: $e');
      return [];
    }
  }

  /// Get game by ID
  static Future<MiniGameModel?> getGameById(String gameId) async {
    try {
      final doc = await _firestore.collection(_gamesCollection).doc(gameId).get();
      if (doc.exists) {
        return MiniGameModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching game by ID: $e');
      return null;
    }
  }

  /// Save (create or update) mini game
  static Future<Map<String, dynamic>> saveGame(MiniGameModel game) async {
    try {
      if (game.id.isEmpty) {
        // Create new game
        final docRef = _firestore.collection(_gamesCollection).doc();
        final gameWithId = game.copyWith(
          id: docRef.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await docRef.set(gameWithId.toMap());
        if (kDebugMode) print('✅ Created mini game: ${game.title} with ID: ${docRef.id}');
        
        return {
          'success': true,
          'message': 'Đã tạo mini game "${game.title}" thành công',
          'id': docRef.id,
        };
      } else {
        // Update existing game
        final updatedGame = game.copyWith(updatedAt: DateTime.now());
        await _firestore.collection(_gamesCollection).doc(game.id).set(updatedGame.toMap());
        if (kDebugMode) print('✅ Updated mini game: ${game.title}');
        
        return {
          'success': true,
          'message': 'Đã cập nhật mini game "${game.title}" thành công',
          'id': game.id,
        };
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error saving mini game: $e');
      return {
        'success': false,
        'message': 'Lỗi lưu mini game: $e',
      };
    }
  }

  /// Delete mini game
  static Future<bool> deleteGame(String gameId) async {
    try {
      await _firestore.collection(_gamesCollection).doc(gameId).delete();
      if (kDebugMode) print('✅ Deleted mini game: $gameId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting mini game: $e');
      return false;
    }
  }

  /// Save game score
  static Future<bool> saveGameScore(GameScoreModel score) async {
    try {
      final docRef = _firestore.collection(_scoresCollection).doc();
      final scoreWithId = GameScoreModel(
        id: docRef.id,
        userId: score.userId,
        gameId: score.gameId,
        gameType: score.gameType,
        score: score.score,
        maxScore: score.maxScore,
        timeSeconds: score.timeSeconds,
        correctAnswers: score.correctAnswers,
        wrongAnswers: score.wrongAnswers,
        accuracy: score.accuracy,
        playedAt: score.playedAt,
        gameDetails: score.gameDetails,
      );
      
      await docRef.set(scoreWithId.toMap());
      
      // Update game play count and average score
      await _updateGameStats(score.gameId, score.score);
      
      if (kDebugMode) print('✅ Saved game score: ${score.score}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving game score: $e');
      return false;
    }
  }

  /// Update game statistics (admin only)
  static Future<void> _updateGameStats(String gameId, int newScore) async {
    try {
      // Check if current user is admin before updating stats
      final isAdmin = await _isCurrentUserAdmin();
      if (!isAdmin) {
        if (kDebugMode) print('⚠️ Non-admin user cannot update game stats');
        return;
      }
      
      final gameDoc = await _firestore.collection(_gamesCollection).doc(gameId).get();
      if (gameDoc.exists) {
        final game = MiniGameModel.fromFirestore(gameDoc);
        final newPlayCount = game.playCount + 1;
        final newAverage = ((game.averageScore * game.playCount) + newScore) / newPlayCount;
        
        await _firestore.collection(_gamesCollection).doc(gameId).update({
          'playCount': newPlayCount,
          'averageScore': newAverage,
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error updating game stats: $e');
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

  /// Get user's scores for a game
  static Future<List<GameScoreModel>> getUserGameScores(String userId, String gameId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_scoresCollection)
          .where('userId', isEqualTo: userId)
          .where('gameId', isEqualTo: gameId)
          .orderBy('playedAt', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => GameScoreModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching user game scores: $e');
      return [];
    }
  }

  /// Get user's best scores
  static Future<List<GameScoreModel>> getUserBestScores(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_scoresCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('score', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => GameScoreModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching user best scores: $e');
      return [];
    }
  }

  /// Get leaderboard for a game
  static Future<List<GameScoreModel>> getGameLeaderboard(String gameId, {int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_scoresCollection)
          .where('gameId', isEqualTo: gameId)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => GameScoreModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching game leaderboard: $e');
      return [];
    }
  }

  /// Get game statistics
  static Future<Map<String, dynamic>> getGameStatistics() async {
    try {
      final gamesSnapshot = await _firestore.collection(_gamesCollection).get();
      final scoresSnapshot = await _firestore.collection(_scoresCollection).get();
      
      final allGames = gamesSnapshot.docs
          .map((doc) => MiniGameModel.fromFirestore(doc))
          .toList();
      
      final allScores = scoresSnapshot.docs
          .map((doc) => GameScoreModel.fromFirestore(doc))
          .toList();

      final byType = <String, int>{};
      final byDifficulty = <int, int>{};
      
      for (var game in allGames) {
        byType[game.gameType] = (byType[game.gameType] ?? 0) + 1;
        byDifficulty[game.difficultyLevel] = (byDifficulty[game.difficultyLevel] ?? 0) + 1;
      }

      return {
        'total_games': allGames.length,
        'active_games': allGames.where((g) => g.isActive).length,
        'total_plays': allScores.length,
        'by_type': byType,
        'by_difficulty': byDifficulty,
        'average_score': allScores.isEmpty 
            ? 0.0 
            : allScores.map((s) => s.score).reduce((a, b) => a + b) / allScores.length,
        'most_played': allGames.isNotEmpty 
            ? allGames.reduce((a, b) => a.playCount > b.playCount ? a : b).title 
            : 'N/A',
      };
    } catch (e) {
      if (kDebugMode) print('Error getting game statistics: $e');
      return {};
    }
  }

  /// Get vocabulary words for game
  static Future<List<VocabularyModel>> getGameVocabulary(MiniGameModel game) async {
    try {
      if (game.vocabularyIds.isEmpty) return [];
      
      final vocabularies = <VocabularyModel>[];
      for (final vocabId in game.vocabularyIds) {
        final doc = await _firestore.collection('vocabulary').doc(vocabId).get();
        if (doc.exists) {
          vocabularies.add(VocabularyModel.fromFirestore(doc));
        }
      }
      
      return vocabularies;
    } catch (e) {
      if (kDebugMode) print('Error fetching game vocabulary: $e');
      return [];
    }
  }

  /// Search games
  static Future<List<MiniGameModel>> searchGames(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_gamesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final allGames = querySnapshot.docs
          .map((doc) => MiniGameModel.fromFirestore(doc))
          .toList();

      // Client-side filtering
      return allGames.where((game) {
        return game.title.toLowerCase().contains(query.toLowerCase()) ||
               game.description.toLowerCase().contains(query.toLowerCase()) ||
               game.gameTypeName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error searching games: $e');
      return [];
    }
  }
}

