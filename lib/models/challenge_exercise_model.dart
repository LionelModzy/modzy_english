import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_model.dart';

/// Model for challenge exercises - separate from regular quizzes
/// These are specifically designed for friend challenges
class ChallengeExerciseModel {
  final String id;
  final String title;
  final String description;
  final String challengeType; // 'quiz_rush', 'vocab_duel', 'lesson_sprint'
  final List<QuizQuestion> questions;
  final int timeLimit; // in seconds for challenges
  final bool isActive;
  final String category;
  final int difficultyLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final Map<String, dynamic> metadata;

  ChallengeExerciseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.questions,
    required this.timeLimit,
    required this.isActive,
    required this.category,
    required this.difficultyLevel,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    required this.metadata,
  });

  factory ChallengeExerciseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ChallengeExerciseModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      challengeType: data['challengeType'] ?? 'quiz_rush',
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
      timeLimit: data['timeLimit'] ?? 60,
      isActive: data['isActive'] ?? true,
      category: data['category'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory ChallengeExerciseModel.fromMap(Map<String, dynamic> map) {
    return ChallengeExerciseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      challengeType: map['challengeType'] ?? 'quiz_rush',
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
      timeLimit: map['timeLimit'] ?? 60,
      isActive: map['isActive'] ?? true,
      category: map['category'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
      createdBy: map['createdBy'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'challengeType': challengeType,
      'questions': questions.map((q) => q.toMap()).toList(),
      'timeLimit': timeLimit,
      'isActive': isActive,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  ChallengeExerciseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? challengeType,
    List<QuizQuestion>? questions,
    int? timeLimit,
    bool? isActive,
    String? category,
    int? difficultyLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return ChallengeExerciseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      challengeType: challengeType ?? this.challengeType,
      questions: questions ?? this.questions,
      timeLimit: timeLimit ?? this.timeLimit,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert to QuizModel for compatibility with QuizScreen
  QuizModel toQuizModel() {
    // Convert seconds to minutes, ensure at least 1 minute if timeLimit > 0
    final minutes = timeLimit > 0 ? (timeLimit / 60).ceil().clamp(1, double.infinity).toInt() : 0;
    
    return QuizModel(
      id: id,
      title: title,
      description: description,
      lessonId: null,
      questions: questions,
      timeLimit: minutes,
      passingScore: 0, // Not used in challenges
      isActive: isActive,
      category: category,
      difficultyLevel: difficultyLevel,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      metadata: metadata,
    );
  }

  String get formattedTimeLimit {
    if (timeLimit < 60) return '${timeLimit} giây';
    int minutes = timeLimit ~/ 60;
    int seconds = timeLimit % 60;
    if (seconds == 0) return '${minutes} phút';
    return '${minutes}p ${seconds}s';
  }

  String get difficultyLevelName {
    switch (difficultyLevel) {
      case 1: return 'Cơ bản';
      case 2: return 'Sơ cấp';
      case 3: return 'Trung cấp';
      case 4: return 'Cao cấp';
      case 5: return 'Nâng cao';
      default: return 'Cơ bản';
    }
  }

  int get totalQuestions => questions.length;

  @override
  String toString() {
    return 'ChallengeExerciseModel(id: $id, title: $title, type: $challengeType, questions: ${questions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChallengeExerciseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

