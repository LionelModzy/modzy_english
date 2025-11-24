import 'package:cloud_firestore/cloud_firestore.dart';

/// Base mini-game model
class MiniGameModel {
  final String id;
  final String gameType; // 'word_match', 'word_scramble', 'word_search'
  final String title;
  final String description;
  final int difficultyLevel; // 1-5
  final String category;
  final List<String> vocabularyIds; // Reference to vocabulary words
  final Map<String, dynamic> gameData; // Game-specific data
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String createdBy;
  final int playCount;
  final double averageScore;
  final Map<String, dynamic> metadata;

  MiniGameModel({
    required this.id,
    required this.gameType,
    required this.title,
    required this.description,
    required this.difficultyLevel,
    required this.category,
    required this.vocabularyIds,
    required this.gameData,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.createdBy,
    required this.playCount,
    required this.averageScore,
    required this.metadata,
  });

  factory MiniGameModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return MiniGameModel(
      id: doc.id,
      gameType: data['gameType'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? 1,
      category: data['category'] ?? '',
      vocabularyIds: List<String>.from(data['vocabularyIds'] ?? []),
      gameData: Map<String, dynamic>.from(data['gameData'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      playCount: data['playCount'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory MiniGameModel.fromMap(Map<String, dynamic> map) {
    return MiniGameModel(
      id: map['id'] ?? '',
      gameType: map['gameType'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      category: map['category'] ?? '',
      vocabularyIds: List<String>.from(map['vocabularyIds'] ?? []),
      gameData: Map<String, dynamic>.from(map['gameData'] ?? {}),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'] ?? '',
      playCount: map['playCount'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameType': gameType,
      'title': title,
      'description': description,
      'difficultyLevel': difficultyLevel,
      'category': category,
      'vocabularyIds': vocabularyIds,
      'gameData': gameData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'createdBy': createdBy,
      'playCount': playCount,
      'averageScore': averageScore,
      'metadata': metadata,
    };
  }

  MiniGameModel copyWith({
    String? id,
    String? gameType,
    String? title,
    String? description,
    int? difficultyLevel,
    String? category,
    List<String>? vocabularyIds,
    Map<String, dynamic>? gameData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? createdBy,
    int? playCount,
    double? averageScore,
    Map<String, dynamic>? metadata,
  }) {
    return MiniGameModel(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      title: title ?? this.title,
      description: description ?? this.description,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      category: category ?? this.category,
      vocabularyIds: vocabularyIds ?? this.vocabularyIds,
      gameData: gameData ?? this.gameData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      playCount: playCount ?? this.playCount,
      averageScore: averageScore ?? this.averageScore,
      metadata: metadata ?? this.metadata,
    );
  }

  String get difficultyLevelName {
    switch (difficultyLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Elementary';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Upper Intermediate';
      case 5:
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }

  String get vietnameseDifficultyName {
    switch (difficultyLevel) {
      case 1:
        return 'Cơ bản';
      case 2:
        return 'Sơ cấp';
      case 3:
        return 'Trung cấp';
      case 4:
        return 'Trung cấp cao';
      case 5:
        return 'Nâng cao';
      default:
        return 'Cơ bản';
    }
  }

  String get gameTypeName {
    switch (gameType) {
      case 'word_match':
        return 'Word Match';
      case 'word_scramble':
        return 'Word Scramble';
      case 'word_search':
        return 'Word Search';
      default:
        return gameType;
    }
  }

  String get vietnameseGameTypeName {
    switch (gameType) {
      case 'word_match':
        return 'Ghép Cặp Từ';
      case 'word_scramble':
        return 'Xếp Chữ';
      case 'word_search':
        return 'Tìm Từ';
      default:
        return gameType;
    }
  }

  @override
  String toString() {
    return 'MiniGameModel(id: $id, gameType: $gameType, title: $title, difficultyLevel: $difficultyLevel)';
  }
}

/// Game score/session model
class GameScoreModel {
  final String id;
  final String userId;
  final String gameId;
  final String gameType;
  final int score;
  final int maxScore;
  final int timeSeconds;
  final int correctAnswers;
  final int wrongAnswers;
  final double accuracy;
  final DateTime playedAt;
  final Map<String, dynamic> gameDetails;

  GameScoreModel({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.gameType,
    required this.score,
    required this.maxScore,
    required this.timeSeconds,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.accuracy,
    required this.playedAt,
    required this.gameDetails,
  });

  factory GameScoreModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return GameScoreModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      gameId: data['gameId'] ?? '',
      gameType: data['gameType'] ?? '',
      score: data['score'] ?? 0,
      maxScore: data['maxScore'] ?? 0,
      timeSeconds: data['timeSeconds'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      wrongAnswers: data['wrongAnswers'] ?? 0,
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
      playedAt: (data['playedAt'] as Timestamp).toDate(),
      gameDetails: Map<String, dynamic>.from(data['gameDetails'] ?? {}),
    );
  }

  factory GameScoreModel.fromMap(Map<String, dynamic> map) {
    return GameScoreModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      gameId: map['gameId'] ?? '',
      gameType: map['gameType'] ?? '',
      score: map['score'] ?? 0,
      maxScore: map['maxScore'] ?? 0,
      timeSeconds: map['timeSeconds'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      playedAt: map['playedAt'] is Timestamp
          ? (map['playedAt'] as Timestamp).toDate()
          : DateTime.parse(map['playedAt']),
      gameDetails: Map<String, dynamic>.from(map['gameDetails'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'gameId': gameId,
      'gameType': gameType,
      'score': score,
      'maxScore': maxScore,
      'timeSeconds': timeSeconds,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'accuracy': accuracy,
      'playedAt': Timestamp.fromDate(playedAt),
      'gameDetails': gameDetails,
    };
  }

  String get formattedTime {
    final minutes = timeSeconds ~/ 60;
    final seconds = timeSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  double get scorePercentage {
    if (maxScore == 0) return 0;
    return (score / maxScore) * 100;
  }

  @override
  String toString() {
    return 'GameScoreModel(id: $id, gameType: $gameType, score: $score/$maxScore, accuracy: ${accuracy.toStringAsFixed(1)}%)';
  }
}

