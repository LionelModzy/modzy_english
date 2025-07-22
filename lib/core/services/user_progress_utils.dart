import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../services/learning_progress_service.dart';
import '../../features/auth/data/auth_repository.dart';

class UserProgressUtils {
  /// Calculate XP based on stats
  static int calculateXP({
    required int lessonsCompleted,
    required int vocabularyLearned,
    required int streak,
    required int accuracy,
    required int totalStudyTime,
  }) {
    int xp = 0;
    xp += lessonsCompleted * 10;
    xp += vocabularyLearned * 2;
    xp += streak * 5;
    xp += (accuracy >= 80 ? 10 : 0);
    xp += (totalStudyTime ~/ 60); // 1 XP mỗi giờ học
    return xp;
  }

  /// Determine level and progress percentage from XP
  static Map<String, dynamic> getLevelFromXP(int xp) {
    // Example XP table
    final levels = [0, 50, 150, 300, 500, 800, 1200];
    int level = 1;
    int nextLevelXP = 50;
    for (int i = 1; i < levels.length; i++) {
      if (xp >= levels[i]) {
        level = i + 1;
        nextLevelXP = (i + 1 < levels.length) ? levels[i + 1] : levels.last + 200;
      } else {
        nextLevelXP = levels[i];
        break;
      }
    }
    int prevLevelXP = levels[level - 1];
    double percent = ((xp - prevLevelXP) / (nextLevelXP - prevLevelXP) * 100).clamp(0, 100);
    return {
      'level': level,
      'progressPercentage': percent,
      'xp': xp,
      'nextLevelXP': nextLevelXP,
    };
  }

  /// Aggregate user progress and update user document
  static Future<void> syncUserProgressWithStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final stats = await LearningProgressService.getLearningStats();
    final lessons = stats['completedLessons'] ?? 0;
    final vocab = stats['totalPractices'] ?? 0;
    final streak = stats['currentStreak'] ?? 0;
    final accuracy = stats['averageAccuracy'] ?? 0;
    final totalStudyTime = stats['totalStudyTime'] ?? 0;
    final xp = calculateXP(
      lessonsCompleted: lessons,
      vocabularyLearned: vocab,
      streak: streak,
      accuracy: accuracy,
      totalStudyTime: totalStudyTime,
    );
    final levelData = getLevelFromXP(xp);
    await AuthRepository.updateUserProgress(
      uid: uid,
      totalLessonsCompleted: lessons,
      totalVocabularyLearned: vocab,
      currentLevel: levelData['level'],
      progressPercentage: levelData['progressPercentage'],
    );
  }
} 