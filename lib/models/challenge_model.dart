import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const declined = 'declined';
  static const completed = 'completed';

  static const allowedStatuses = {pending, accepted, declined, completed};

  static bool isValid(String status) => allowedStatuses.contains(status);
}

class ChallengeModel {
  final String id;
  final String challengerId;
  final String challengerName;
  final String opponentId;
  final String opponentName;
  final String challengeType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;
  final List<String> participants;
  final Map<String, dynamic>? results;

  ChallengeModel({
    required this.id,
    required this.challengerId,
    required this.challengerName,
    required this.opponentId,
    required this.opponentName,
    required this.challengeType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    required this.metadata,
    required this.participants,
    this.results,
  });

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeModel(
      id: doc.id,
      challengerId: data['challengerId'] ?? '',
      challengerName: data['challengerName'] ?? '',
      opponentId: data['opponentId'] ?? '',
      opponentName: data['opponentName'] ?? '',
      challengeType: data['challengeType'] ?? 'quiz_rush',
      status: data['status'] ?? ChallengeStatus.pending,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      expiresAt: data['expiresAt'] != null ? _parseTimestamp(data['expiresAt']) : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      participants: List<String>.from(data['participants'] ?? const []),
      results: data['results'] != null ? Map<String, dynamic>.from(data['results']) : null,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  bool get isPending => status == ChallengeStatus.pending;
  bool get isAccepted => status == ChallengeStatus.accepted;
  bool get isDeclined => status == ChallengeStatus.declined;
  bool get isCompleted => status == ChallengeStatus.completed;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get friendlyLabel {
    switch (challengeType) {
      case 'vocab_duel':
        return 'Vocabulary Duel';
      case 'lesson_sprint':
        return 'Lesson Sprint';
      default:
        return 'Quiz Rush';
    }
  }

  Map<String, dynamic>? get challengerResult {
    if (results == null) return null;
    return results![challengerId] as Map<String, dynamic>?;
  }

  Map<String, dynamic>? get opponentResult {
    if (results == null) return null;
    return results![opponentId] as Map<String, dynamic>?;
  }

  String? get winnerId {
    if (!isCompleted || results == null) return null;
    final challengerScore = challengerResult?['score'] as int? ?? 0;
    final opponentScore = opponentResult?['score'] as int? ?? 0;
    if (challengerScore > opponentScore) return challengerId;
    if (opponentScore > challengerScore) return opponentId;
    return null; // Tie
  }
}

