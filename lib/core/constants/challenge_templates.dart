class ChallengeTemplate {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Map<String, dynamic> metadata;

  const ChallengeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.metadata,
  });

  Map<String, dynamic> toMetadata() {
    return {
      ...metadata,
      'title': title,
      'description': description,
      'emoji': emoji,
    };
  }
}

class ChallengeTemplates {
  static const quizRush = ChallengeTemplate(
    id: 'quiz_rush',
    title: 'Quiz Rush',
    description: 'Trả lời 5 câu hỏi nhanh nhất có thể. Thời gian: 60 giây.',
    emoji: '⚡️',
    metadata: {
      'questions': 5,
      'timeLimitSeconds': 60,
    },
  );

  static const vocabDuel = ChallengeTemplate(
    id: 'vocab_duel',
    title: 'Vocabulary Duel',
    description: 'Ghi nhớ 10 từ mới và so sánh điểm.',
    emoji: '🧠',
    metadata: {
      'words': 10,
      'mode': 'flashcard',
    },
  );

  static const lessonSprint = ChallengeTemplate(
    id: 'lesson_sprint',
    title: 'Lesson Sprint',
    description: 'Hoàn thành 1 bài học trong 5 phút.',
    emoji: '🏃‍♂️',
    metadata: {
      'lessons': 1,
      'timeLimitMinutes': 5,
    },
  );

  static const speedChallenge = ChallengeTemplate(
    id: 'speed_challenge',
    title: 'Speed Challenge',
    description: 'Trả lời càng nhiều câu hỏi càng tốt trong thời gian giới hạn.',
    emoji: '⏱️',
    metadata: {
      'questions': 10,
      'timeLimitSeconds': 120,
    },
  );

  static const accuracyMaster = ChallengeTemplate(
    id: 'accuracy_master',
    title: 'Accuracy Master',
    description: 'Đạt độ chính xác cao nhất với số câu hỏi giới hạn.',
    emoji: '🎯',
    metadata: {
      'questions': 15,
      'timeLimitSeconds': 300,
      'focus': 'accuracy',
    },
  );

  static const grammarBattle = ChallengeTemplate(
    id: 'grammar_battle',
    title: 'Grammar Battle',
    description: 'Thách đấu ngữ pháp với bạn bè.',
    emoji: '📚',
    metadata: {
      'category': 'Grammar',
      'questions': 10,
      'timeLimitSeconds': 180,
    },
  );

  static const List<ChallengeTemplate> all = [
    quizRush,
    vocabDuel,
    lessonSprint,
    speedChallenge,
    accuracyMaster,
    grammarBattle,
  ];

  static ChallengeTemplate byId(String id) {
    return all.firstWhere(
      (template) => template.id == id,
      orElse: () => quizRush,
    );
  }
}

