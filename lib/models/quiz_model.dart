import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int difficultyLevel; // 1-5
  final int timeLimit; // in minutes, 0 for unlimited
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isPremium;
  final String createdBy;
  final Map<String, dynamic> metadata;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficultyLevel,
    required this.timeLimit,
    required this.questions,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.isPremium,
    required this.createdBy,
    required this.metadata,
  });

  // Factory constructor from Firestore document
  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? 1,
      timeLimit: data['timeLimit'] ?? 0,
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((question) => QuizQuestion.fromMap(question))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      isPremium: data['isPremium'] ?? false,
      createdBy: data['createdBy'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Factory constructor from Map
  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      timeLimit: map['timeLimit'] ?? 0,
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((question) => QuizQuestion.fromMap(question))
          .toList(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
      isActive: map['isActive'] ?? true,
      isPremium: map['isPremium'] ?? false,
      createdBy: map['createdBy'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'timeLimit': timeLimit,
      'questions': questions.map((question) => question.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'isPremium': isPremium,
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  // Copy with method
  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? difficultyLevel,
    int? timeLimit,
    List<QuizQuestion>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPremium,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      timeLimit: timeLimit ?? this.timeLimit,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPremium: isPremium ?? this.isPremium,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get difficulty level name
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

  // Get formatted time limit
  String get formattedTimeLimit {
    if (timeLimit == 0) return 'Unlimited';
    if (timeLimit < 60) return '${timeLimit}m';
    
    int hours = timeLimit ~/ 60;
    int minutes = timeLimit % 60;
    return '${hours}h ${minutes}m';
  }

  // Get total questions count
  int get totalQuestions => questions.length;

  // Check if quiz is timed
  bool get isTimed => timeLimit > 0;

  @override
  String toString() {
    return 'QuizModel(id: $id, title: $title, category: $category, questions: ${questions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is QuizModel &&
        other.id == id &&
        other.title == title;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode;
  }
}

// Quiz Question Model
class QuizQuestion {
  final String id;
  final String question;
  final String type; // multiple_choice, true_false, fill_blank, essay
  final List<String> options; // For multiple choice
  final String correctAnswer;
  final String? explanation;
  final String? imageUrl;
  final String? audioUrl;
  final int points;
  final Map<String, dynamic> metadata;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.imageUrl,
    this.audioUrl,
    required this.points,
    required this.metadata,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      type: map['type'] ?? 'multiple_choice',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      explanation: map['explanation'],
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      points: map['points'] ?? 1,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'points': points,
      'metadata': metadata,
    };
  }

  // Check if question has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // Check if question has audio
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  // Check if question has explanation
  bool get hasExplanation => explanation != null && explanation!.isNotEmpty;

  // Get question type display name
  String get typeDisplayName {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'true_false':
        return 'True/False';
      case 'fill_blank':
        return 'Fill in the Blank';
      case 'essay':
        return 'Essay';
      default:
        return 'Multiple Choice';
    }
  }

  @override
  String toString() {
    return 'QuizQuestion(id: $id, type: $type, points: $points)';
  }
}

// Quiz Result Model
class QuizResult {
  final String id;
  final String userId;
  final String quizId;
  final List<QuizAnswer> answers;
  final int score;
  final int totalPoints;
  final int timeSpent; // in seconds
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  QuizResult({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.answers,
    required this.score,
    required this.totalPoints,
    required this.timeSpent,
    required this.completedAt,
    required this.metadata,
  });

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      quizId: map['quizId'] ?? '',
      answers: (map['answers'] as List<dynamic>? ?? [])
          .map((answer) => QuizAnswer.fromMap(answer))
          .toList(),
      score: map['score'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      timeSpent: map['timeSpent'] ?? 0,
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : DateTime.parse(map['completedAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'quizId': quizId,
      'answers': answers.map((answer) => answer.toMap()).toList(),
      'score': score,
      'totalPoints': totalPoints,
      'timeSpent': timeSpent,
      'completedAt': Timestamp.fromDate(completedAt),
      'metadata': metadata,
    };
  }

  // Get percentage score
  double get percentage => totalPoints > 0 ? (score / totalPoints * 100) : 0.0;

  // Get formatted time spent
  String get formattedTimeSpent {
    int minutes = timeSpent ~/ 60;
    int seconds = timeSpent % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  String toString() {
    return 'QuizResult(id: $id, score: $score/$totalPoints, percentage: ${percentage.toStringAsFixed(1)}%)';
  }
}

// Quiz Answer Model
class QuizAnswer {
  final String questionId;
  final String userAnswer;
  final bool isCorrect;
  final int pointsEarned;

  QuizAnswer({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.pointsEarned,
  });

  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      questionId: map['questionId'] ?? '',
      userAnswer: map['userAnswer'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
      pointsEarned: map['pointsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
    };
  }

  @override
  String toString() {
    return 'QuizAnswer(questionId: $questionId, isCorrect: $isCorrect, points: $pointsEarned)';
  }
} 