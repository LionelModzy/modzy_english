import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String? lessonId; // Associated lesson ID
  final List<QuizQuestion> questions;
  final int timeLimit; // in minutes, 0 means no time limit
  final int passingScore; // percentage needed to pass
  final bool isActive;
  final String category;
  final int difficultyLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final Map<String, dynamic> metadata;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    this.lessonId,
    required this.questions,
    required this.timeLimit,
    required this.passingScore,
    required this.isActive,
    required this.category,
    required this.difficultyLevel,
    required this.createdAt,
    this.updatedAt,
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
      lessonId: data['lessonId'],
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
      timeLimit: data['timeLimit'] ?? 0,
      passingScore: data['passingScore'] ?? 70,
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

  // Factory constructor from Map
  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      lessonId: map['lessonId'],
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
      timeLimit: map['timeLimit'] ?? 0,
      passingScore: map['passingScore'] ?? 70,
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

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lessonId': lessonId,
      'questions': questions.map((q) => q.toMap()).toList(),
      'timeLimit': timeLimit,
      'passingScore': passingScore,
      'isActive': isActive,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  // Copy with method
  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? lessonId,
    List<QuizQuestion>? questions,
    int? timeLimit,
    int? passingScore,
    bool? isActive,
    String? category,
    int? difficultyLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lessonId: lessonId ?? this.lessonId,
      questions: questions ?? this.questions,
      timeLimit: timeLimit ?? this.timeLimit,
      passingScore: passingScore ?? this.passingScore,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get formatted time limit
  String get formattedTimeLimit {
    if (timeLimit == 0) return 'Không giới hạn';
    if (timeLimit < 60) return '${timeLimit} phút';
    int hours = timeLimit ~/ 60;
    int minutes = timeLimit % 60;
    return '${hours}h ${minutes}m';
  }

  // Get difficulty level name
  String get difficultyLevelName {
    switch (difficultyLevel) {
      case 1: return 'Beginner';
      case 2: return 'Elementary';
      case 3: return 'Intermediate';
      case 4: return 'Upper Intermediate';
      case 5: return 'Advanced';
      default: return 'Beginner';
    }
  }

  // Get total questions count
  int get totalQuestions => questions.length;

  // Check if quiz is timed
  bool get isTimed => timeLimit > 0;

  @override
  String toString() {
    return 'QuizModel(id: $id, title: $title, questions: ${questions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Quiz Question Model
class QuizQuestion {
  final String id;
  final String question;
  final QuizQuestionType type;
  final List<String> options; // For multiple choice
  final String correctAnswer;
  final List<String> correctAnswers; // For multiple select
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
    required this.correctAnswers,
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
      type: QuizQuestionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => QuizQuestionType.multipleChoice,
      ),
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      correctAnswers: List<String>.from(map['correctAnswers'] ?? []),
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
      'type': type.toString().split('.').last,
      'options': options,
      'correctAnswer': correctAnswer,
      'correctAnswers': correctAnswers,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'points': points,
      'metadata': metadata,
    };
  }

  QuizQuestion copyWith({
    String? id,
    String? question,
    QuizQuestionType? type,
    List<String>? options,
    String? correctAnswer,
    List<String>? correctAnswers,
    String? explanation,
    String? imageUrl,
    String? audioUrl,
    int? points,
    Map<String, dynamic>? metadata,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      points: points ?? this.points,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'QuizQuestion(id: $id, question: $question, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizQuestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Quiz Question Types
enum QuizQuestionType {
  multipleChoice,
  multipleSelect,
  trueFalse,
  fillInBlank,
  shortAnswer,
  matching,
  ordering,
}

// Quiz Result Model
class QuizResult {
  final String id;
  final String quizId;
  final String userId;
  final List<QuizAnswer> answers;
  final int score;
  final int totalPoints;
  final double percentage;
  final bool passed;
  final Duration timeSpent;
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.answers,
    required this.score,
    required this.totalPoints,
    required this.percentage,
    required this.passed,
    required this.timeSpent,
    required this.completedAt,
    required this.metadata,
  });

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'] ?? '',
      quizId: map['quizId'] ?? '',
      userId: map['userId'] ?? '',
      answers: (map['answers'] as List<dynamic>? ?? [])
          .map((a) => QuizAnswer.fromMap(a))
          .toList(),
      score: map['score'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      passed: map['passed'] ?? false,
      timeSpent: Duration(seconds: map['timeSpentSeconds'] ?? 0),
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : DateTime.parse(map['completedAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'answers': answers.map((a) => a.toMap()).toList(),
      'score': score,
      'totalPoints': totalPoints,
      'percentage': percentage,
      'passed': passed,
      'timeSpentSeconds': timeSpent.inSeconds,
      'completedAt': Timestamp.fromDate(completedAt),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'QuizResult(score: $score/$totalPoints, percentage: ${percentage.toStringAsFixed(1)}%)';
  }
}

// Quiz Answer Model
class QuizAnswer {
  final String questionId;
  final List<String> selectedAnswers;
  final String? textAnswer;
  final bool isCorrect;
  final int pointsEarned;

  QuizAnswer({
    required this.questionId,
    required this.selectedAnswers,
    this.textAnswer,
    required this.isCorrect,
    required this.pointsEarned,
  });

  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      questionId: map['questionId'] ?? '',
      selectedAnswers: List<String>.from(map['selectedAnswers'] ?? []),
      textAnswer: map['textAnswer'],
      isCorrect: map['isCorrect'] ?? false,
      pointsEarned: map['pointsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedAnswers': selectedAnswers,
      'textAnswer': textAnswer,
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
    };
  }

  @override
  String toString() {
    return 'QuizAnswer(questionId: $questionId, isCorrect: $isCorrect, points: $pointsEarned)';
  }
} 