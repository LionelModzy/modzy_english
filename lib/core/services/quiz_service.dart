import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/quiz_model.dart';

class QuizService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'quizzes';
  static const String _resultsCollection = 'quiz_results';

  /// Get current authenticated user ID
  static String? _getCurrentUserId() {
    final user = _auth.currentUser;
    return user?.uid;
  }

  /// Get all quizzes
  static Future<List<QuizModel>> getAllQuizzes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final quizzes = querySnapshot.docs
          .map((doc) => QuizModel.fromFirestore(doc))
          .toList();

      // If no quizzes exist, create sample data
      if (quizzes.isEmpty) {
        await _createSampleQuizzes();
        // Fetch again after creating sample data
        final newSnapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        
        return newSnapshot.docs
            .map((doc) => QuizModel.fromFirestore(doc))
            .toList();
      }

      return quizzes;
    } catch (e) {
      if (kDebugMode) print('Error fetching quizzes: $e');
      return [];
    }
  }

  /// Get all quizzes for admin panel (both active and inactive, no auto-creation)
  static Future<List<QuizModel>> getAllQuizzesForAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching quizzes for admin: $e');
      return [];
    }
  }

  /// Create sample quiz data for immediate user experience
  static Future<void> _createSampleQuizzes() async {
    try {
      if (kDebugMode) print('🎯 Creating sample quiz data...');
      
      final sampleQuizzes = [
        // Grammar Quiz - Beginner
        QuizModel(
          id: '',
          title: 'Basic English Grammar',
          description: 'Test your knowledge of basic English grammar rules including present tense and articles.',
          category: 'Grammar',
          difficultyLevel: 1,
          timeLimit: 10,
          questions: [
            QuizQuestion(
              id: 'q1',
              question: 'Choose the correct form: "I ___ a student."',
              type: QuizQuestionType.multipleChoice,
              options: ['am', 'is', 'are', 'be'],
              correctAnswer: 'am',
              correctAnswers: ['am'],
              explanation: '"I" always takes "am" in present tense.',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 'q2', 
              question: 'Select the correct article: "___ apple is red."',
              type: QuizQuestionType.multipleChoice,
              options: ['A', 'An', 'The', 'No article'],
              correctAnswer: 'An',
              correctAnswers: ['An'],
              explanation: 'Use "an" before words starting with vowel sounds.',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 'q3',
              question: 'Which sentences are correct? (Select all)',
              type: QuizQuestionType.multipleSelect,
              options: ['She go to school', 'She goes to school', 'They goes to school', 'They go to school'],
              correctAnswer: '',
              correctAnswers: ['She goes to school', 'They go to school'],
              explanation: 'Third person singular (he/she/it) takes "s" in present tense.',
              points: 15,
              metadata: {},
            ),
            QuizQuestion(
              id: 'q4',
              question: 'Complete the sentence: "We ___ playing football yesterday."',
              type: QuizQuestionType.fillInBlank,
              options: [],
              correctAnswer: 'were',
              correctAnswers: ['were'],
              explanation: '"We" takes "were" in past continuous tense.',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 'q5',
              question: 'What is the past tense of "go"?',
              type: QuizQuestionType.shortAnswer,
              options: [],
              correctAnswer: 'went',
              correctAnswers: ['went'],
              explanation: '"Go" is an irregular verb. Past tense is "went".',
              points: 10,
              metadata: {},
            ),
          ],
          passingScore: 35,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          createdBy: 'system',
          metadata: {'sampleData': true, 'autoGenerated': true},
        ),

        // Vocabulary Quiz - Elementary  
        QuizModel(
          id: '',
          title: 'Common English Vocabulary',
          description: 'Test your knowledge of common English words and their meanings.',
          category: 'Vocabulary',
          difficultyLevel: 2,
          timeLimit: 15,
          questions: [
            QuizQuestion(
              id: 'v1',
              question: 'What does "enormous" mean?',
              type: QuizQuestionType.multipleChoice,
              options: ['Very small', 'Very large', 'Very fast', 'Very slow'],
              correctAnswer: 'Very large',
              correctAnswers: ['Very large'],
              explanation: '"Enormous" means extremely large or huge.',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 'v2',
              question: 'Choose the synonym for "happy":',
              type: QuizQuestionType.multipleChoice,
              options: ['Sad', 'Angry', 'Joyful', 'Tired'],
              correctAnswer: 'Joyful',
              correctAnswers: ['Joyful'],
              explanation: '"Joyful" means feeling great pleasure and happiness.',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 'v3',
              question: 'Which words mean "to look at something carefully"? (Select all)',
              type: QuizQuestionType.multipleSelect,
              options: ['Examine', 'Ignore', 'Inspect', 'Overlook'],
              correctAnswer: '',
              correctAnswers: ['Examine', 'Inspect'],
              explanation: 'Both "examine" and "inspect" mean to look at something carefully.',
              points: 15,
              metadata: {},
            ),
            QuizQuestion(
              id: 'v4',
              question: 'Complete: "The opposite of \'difficult\' is ___."',
              type: QuizQuestionType.fillInBlank,
              options: [],
              correctAnswer: 'easy',
              correctAnswers: ['easy', 'simple'],
              explanation: '"Easy" or "simple" are antonyms of "difficult".',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 'v5',
              question: 'What do you call a person who teaches?',
              type: QuizQuestionType.shortAnswer,
              options: [],
              correctAnswer: 'teacher',
              correctAnswers: ['teacher', 'instructor', 'educator'],
              explanation: 'A teacher, instructor, or educator is someone who teaches.',
              points: 10,
              metadata: {},
            ),
          ],
          passingScore: 40,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          isActive: true,
          createdBy: 'system',
          metadata: {'sampleData': true, 'autoGenerated': true},
        ),

        // Speaking Quiz - Upper Intermediate
        QuizModel(
          id: '',
          title: 'English Speaking Patterns',
          description: 'Practice common speaking patterns and conversational English.',
          category: 'Speaking',
          difficultyLevel: 4,
          timeLimit: 25,
          questions: [
            QuizQuestion(
              id: 's1',
              question: 'Which is the most formal way to greet someone?',
              type: QuizQuestionType.multipleChoice,
              options: ['Hey there!', 'What\'s up?', 'Good morning', 'Yo!'],
              correctAnswer: 'Good morning',
              correctAnswers: ['Good morning'],
              explanation: '"Good morning" is the most formal and appropriate greeting.',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 's2',
              question: 'How do you politely disagree in a business meeting?',
              type: QuizQuestionType.multipleChoice,
              options: ['You\'re wrong', 'I disagree', 'I see your point, but...', 'That\'s stupid'],
              correctAnswer: 'I see your point, but...',
              correctAnswers: ['I see your point, but...'],
              explanation: 'This phrase acknowledges the other person before presenting your view.',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 's3',
              question: 'Which phrases are appropriate for making suggestions? (Select all)',
              type: QuizQuestionType.multipleSelect,
              options: ['Why don\'t we...?', 'You should do...', 'How about...?', 'I suggest that...'],
              correctAnswer: '',
              correctAnswers: ['Why don\'t we...?', 'How about...?', 'I suggest that...'],
              explanation: 'These are polite ways to make suggestions.',
              points: 15,
              metadata: {},
            ),
            QuizQuestion(
              id: 's4',
              question: 'Complete the polite request: "Would you mind ___ the window?"',
              type: QuizQuestionType.fillInBlank,
              options: [],
              correctAnswer: 'opening',
              correctAnswers: ['opening', 'closing'],
              explanation: '"Would you mind + -ing" is a polite way to make requests.',
              points: 10,
              metadata: {},
            ),
            QuizQuestion(
              id: 's5',
              question: 'How do you politely end a phone conversation?',
              type: QuizQuestionType.shortAnswer,
              options: [],
              correctAnswer: 'talk to you later',
              correctAnswers: ['talk to you later', 'goodbye', 'have a good day', 'take care'],
              explanation: 'These are common polite ways to end phone conversations.',
              points: 10,
              metadata: {},
            ),
          ],
          passingScore: 40,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
          isActive: true,
          createdBy: 'system',
          metadata: {'sampleData': true, 'autoGenerated': true},
        ),
      ];

      // Create quizzes in batch
      final batch = _firestore.batch();
      for (var quiz in sampleQuizzes) {
        final docRef = _firestore.collection(_collection).doc();
        final quizWithId = QuizModel(
          id: docRef.id,
          title: quiz.title,
          description: quiz.description,
          lessonId: quiz.lessonId,
          questions: quiz.questions,
          timeLimit: quiz.timeLimit,
          passingScore: quiz.passingScore,
          isActive: quiz.isActive,
          category: quiz.category,
          difficultyLevel: quiz.difficultyLevel,
          createdAt: quiz.createdAt,
          updatedAt: quiz.updatedAt,
          createdBy: quiz.createdBy,
          metadata: quiz.metadata,
        );
        batch.set(docRef, quizWithId.toMap());
      }

      await batch.commit();
      if (kDebugMode) print('✅ Created ${sampleQuizzes.length} sample quizzes');
    } catch (e) {
      if (kDebugMode) print('❌ Error creating sample quizzes: $e');
    }
  }

  /// Get quizzes by lesson ID
  static Future<List<QuizModel>> getQuizzesByLesson(String lessonId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('lessonId', isEqualTo: lessonId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs
          .map((doc) => QuizModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching lesson quizzes: $e');
      throw Exception('Failed to fetch lesson quizzes: $e');
    }
  }

  /// Get quiz by ID
  static Future<QuizModel?> getQuizById(String quizId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(quizId).get();
      
      if (doc.exists) {
        return QuizModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching quiz: $e');
      return null;
    }
  }

  /// Save quiz result
  static Future<bool> saveQuizResult(QuizResult result) async {
    try {
      await _firestore.collection(_resultsCollection).add(result.toMap());
      if (kDebugMode) print('✅ Quiz result saved');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving quiz result: $e');
      return false;
    }
  }

  /// Get user's quiz results
  static Future<List<QuizResult>> getUserQuizResults() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) print('❌ No authenticated user');
        return [];
      }

      final querySnapshot = await _firestore
          .collection(_resultsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizResult.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching quiz results: $e');
      throw Exception('Failed to fetch quiz results: $e');
    }
  }

  /// Create a new quiz
  static Future<String?> createQuiz(QuizModel quiz) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) print('❌ No authenticated user');
        return null;
      }
      
      final quizWithCreator = QuizModel(
        id: '',
        title: quiz.title,
        description: quiz.description,
        lessonId: quiz.lessonId,
        questions: quiz.questions,
        timeLimit: quiz.timeLimit,
        passingScore: quiz.passingScore,
        isActive: quiz.isActive,
        category: quiz.category,
        difficultyLevel: quiz.difficultyLevel,
        createdAt: quiz.createdAt,
        updatedAt: DateTime.now(),
        createdBy: userId,
        metadata: quiz.metadata,
      );
      
      final docRef = await _firestore.collection(_collection).add(quizWithCreator.toMap());
      if (kDebugMode) print('✅ Quiz created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating quiz: $e');
      return null;
    }
  }

  /// Update quiz
  static Future<bool> updateQuiz(QuizModel quiz) async {
    try {
      await _firestore.collection(_collection).doc(quiz.id).update(quiz.toMap());
      if (kDebugMode) print('✅ Quiz updated: ${quiz.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating quiz: $e');
      return false;
    }
  }

  /// Delete quiz
  static Future<bool> deleteQuiz(String quizId) async {
    try {
      await _firestore.collection(_collection).doc(quizId).delete();
      if (kDebugMode) print('✅ Quiz deleted: $quizId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting quiz: $e');
      return false;
    }
  }

  /// Get user's best result for a specific quiz
  static Future<QuizResult?> getUserBestResult(String quizId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) print('❌ No authenticated user');
        return null;
      }
      
      final querySnapshot = await _firestore
          .collection(_resultsCollection)
          .where('quizId', isEqualTo: quizId)
          .where('userId', isEqualTo: userId)
          .orderBy('score', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return QuizResult.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching user best result: $e');
      return null;
    }
  }

  /// Grade a quiz based on user answers
  static QuizResult gradeQuiz(
    QuizModel quiz,
    List<QuizAnswer> userAnswers,
    Duration timeSpent,
  ) {
    int totalScore = 0;
    int totalPossiblePoints = 0;
    
    // Grade each question and update user answers with scoring
    List<QuizAnswer> gradedAnswers = [];
    
    for (var question in quiz.questions) {
      totalPossiblePoints += question.points;
      
      // Find user's answer for this question
      final userAnswer = userAnswers.firstWhere(
        (answer) => answer.questionId == question.id,
        orElse: () => QuizAnswer(
          questionId: question.id,
          selectedAnswers: [],
          textAnswer: '',
          isCorrect: false,
          pointsEarned: 0,
        ),
      );
      
      // Grade the answer based on question type
      bool isCorrect = false;
      int pointsEarned = 0;
      
      switch (question.type) {
        case QuizQuestionType.multipleChoice:
        case QuizQuestionType.trueFalse:
          // Single correct answer
          if (userAnswer.selectedAnswers.isNotEmpty && 
              userAnswer.selectedAnswers.first == question.correctAnswer) {
            isCorrect = true;
            pointsEarned = question.points;
          }
          break;
          
        case QuizQuestionType.multipleSelect:
          // Multiple correct answers - all must be selected, no wrong ones
          final userSelected = Set<String>.from(userAnswer.selectedAnswers);
          final correctAnswers = Set<String>.from(question.correctAnswers);
          
          if (userSelected.isNotEmpty && userSelected.difference(correctAnswers).isEmpty && 
              correctAnswers.difference(userSelected).isEmpty) {
            isCorrect = true;
            pointsEarned = question.points;
          } else if (userSelected.intersection(correctAnswers).isNotEmpty) {
            // Partial credit for some correct answers
            final correctCount = userSelected.intersection(correctAnswers).length;
            final totalCorrect = correctAnswers.length;
            pointsEarned = (question.points * correctCount / totalCorrect).round();
          }
          break;
          
        case QuizQuestionType.fillInBlank:
        case QuizQuestionType.shortAnswer:
          // Text answers - check against all possible correct answers (case insensitive)
          final userText = userAnswer.textAnswer?.trim().toLowerCase() ?? '';
          if (userText.isNotEmpty) {
            for (String correctAnswer in question.correctAnswers) {
              if (userText == correctAnswer.trim().toLowerCase()) {
                isCorrect = true;
                pointsEarned = question.points;
                break;
              }
            }
          }
          break;
         
        case QuizQuestionType.matching:
          // For matching questions, check if user selections match correct pairs
          // This is a simplified implementation - you may need to adjust based on your matching logic
          final userSelected = Set<String>.from(userAnswer.selectedAnswers);
          final correctAnswers = Set<String>.from(question.correctAnswers);
          
          if (userSelected.isNotEmpty && userSelected.difference(correctAnswers).isEmpty && 
              correctAnswers.difference(userSelected).isEmpty) {
            isCorrect = true;
            pointsEarned = question.points;
          }
          break;
          
        default:
          // Handle any unknown question types
          isCorrect = false;
          pointsEarned = 0;
          break;
      }
      
      // Create graded answer
      final gradedAnswer = QuizAnswer(
        questionId: question.id,
        selectedAnswers: userAnswer.selectedAnswers,
        textAnswer: userAnswer.textAnswer,
        isCorrect: isCorrect,
        pointsEarned: pointsEarned,
      );
      
      gradedAnswers.add(gradedAnswer);
      totalScore += pointsEarned;
    }
    
    final percentage = totalPossiblePoints > 0 ? (totalScore / totalPossiblePoints) * 100 : 0.0;
    final passed = percentage >= quiz.passingScore;
    final currentUserId = _getCurrentUserId();
    
    return QuizResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      quizId: quiz.id,
      userId: currentUserId ?? 'unknown_user',
      answers: gradedAnswers,
      score: totalScore,
      totalPoints: totalPossiblePoints,
      percentage: percentage,
      passed: passed,
      timeSpent: timeSpent,
      completedAt: DateTime.now(),
      metadata: {},
    );
  }

  /// Submit quiz result to Firebase
  static Future<bool> submitQuizResult(QuizResult result) async {
    try {
      await _firestore.collection(_resultsCollection).add(result.toMap());
      if (kDebugMode) print('✅ Quiz result submitted successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error submitting quiz result: $e');
      return false;
    }
  }
} 