import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/challenge_model.dart';

class ChallengeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'challenges';

  static Future<bool> createChallenge({
    required String challengerId,
    required String challengerName,
    required String opponentId,
    required String opponentName,
    required String challengeType,
    Map<String, dynamic>? metadata,
    Duration ttl = const Duration(days: 3),
  }) async {
    try {
      final expiresAt = DateTime.now().add(ttl);

      await _firestore.collection(_collection).add({
        'challengerId': challengerId,
        'challengerName': challengerName,
        'opponentId': opponentId,
        'opponentName': opponentName,
        'challengeType': challengeType,
        'status': ChallengeStatus.pending,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'metadata': metadata ?? {},
        'participants': [challengerId, opponentId],
      });

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating challenge: $e');
      return false;
    }
  }

  static Stream<List<ChallengeModel>> watchChallenges(String userId) {
    if (kDebugMode) {
      print('🔍 Watching challenges for userId: $userId');
    }
    
    // Query challenges where user is challenger
    final challengerStream = _firestore
        .collection(_collection)
        .where('challengerId', isEqualTo: userId)
        .snapshots();
    
    // Query challenges where user is opponent
    final opponentStream = _firestore
        .collection(_collection)
        .where('opponentId', isEqualTo: userId)
        .snapshots();
    
    // Combine both streams using StreamController
    final controller = StreamController<List<ChallengeModel>>();
    final allChallenges = <String, ChallengeModel>{};
    
    void updateChallenges() {
      final challenges = allChallenges.values.toList();
      challenges.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      controller.add(challenges);
    }
    
    StreamSubscription? challengerSub;
    StreamSubscription? opponentSub;
    
    challengerSub = challengerStream.listen((snapshot) {
      if (kDebugMode) {
        print('📦 Challenger stream: ${snapshot.docs.length} documents');
      }
      for (var doc in snapshot.docs) {
        try {
          final challenge = ChallengeModel.fromFirestore(doc);
          allChallenges[challenge.id] = challenge;
          if (kDebugMode) {
            print('  ✓ Added challenger challenge: ${challenge.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ❌ Error parsing challenger challenge ${doc.id}: $e');
          }
        }
      }
      updateChallenges();
    }, onError: (error) {
      if (kDebugMode) {
        print('❌ Error in challenger stream: $error');
      }
    });
    
    opponentSub = opponentStream.listen((snapshot) {
      if (kDebugMode) {
        print('📦 Opponent stream: ${snapshot.docs.length} documents');
      }
      for (var doc in snapshot.docs) {
        try {
          final challenge = ChallengeModel.fromFirestore(doc);
          allChallenges[challenge.id] = challenge;
          if (kDebugMode) {
            print('  ✓ Added opponent challenge: ${challenge.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ❌ Error parsing opponent challenge ${doc.id}: $e');
          }
        }
      }
      updateChallenges();
    }, onError: (error) {
      if (kDebugMode) {
        print('❌ Error in opponent stream: $error');
      }
    });
    
    controller.onCancel = () {
      challengerSub?.cancel();
      opponentSub?.cancel();
    };
    
    return controller.stream;
  }

  static Future<bool> updateChallengeStatus({
    required String challengeId,
    required String status,
    Map<String, dynamic>? extraData,
  }) async {
    if (!ChallengeStatus.isValid(status)) return false;

    try {
      await _firestore.collection(_collection).doc(challengeId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (extraData != null) ...extraData,
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating challenge: $e');
      return false;
    }
  }

  static Future<bool> submitChallengeResult({
    required String challengeId,
    required String userId,
    required int score,
    required int totalPoints,
    required double percentage,
    required Duration timeSpent,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final challengeDoc = await _firestore.collection(_collection).doc(challengeId).get();
      if (!challengeDoc.exists) return false;

      final challengeData = challengeDoc.data() as Map<String, dynamic>;
      final results = Map<String, dynamic>.from(challengeData['results'] ?? {});

      results[userId] = {
        'score': score,
        'totalPoints': totalPoints,
        'percentage': percentage,
        'timeSpentSeconds': timeSpent.inSeconds,
        'completedAt': FieldValue.serverTimestamp(),
        if (extraData != null) ...extraData,
      };

      final bothCompleted = results.keys.length >= 2;
      final newStatus = bothCompleted ? ChallengeStatus.completed : ChallengeStatus.accepted;

      await _firestore.collection(_collection).doc(challengeId).update({
        'results': results,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error submitting challenge result: $e');
      return false;
    }
  }

  static Future<ChallengeModel?> getChallenge(String challengeId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(challengeId).get();
      if (!doc.exists) return null;
      return ChallengeModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) print('❌ Error getting challenge: $e');
      return null;
    }
  }

  // Test method to get all challenges for a user (for debugging)
  static Future<List<ChallengeModel>> getAllChallengesForUser(String userId) async {
    try {
      if (kDebugMode) {
        print('🔍 Getting all challenges for userId: $userId');
      }
      
      // Query challenges where user is challenger
      final challengerSnapshot = await _firestore
          .collection(_collection)
          .where('challengerId', isEqualTo: userId)
          .get();
      
      // Query challenges where user is opponent
      final opponentSnapshot = await _firestore
          .collection(_collection)
          .where('opponentId', isEqualTo: userId)
          .get();
      
      if (kDebugMode) {
        print('📦 Challenger query: ${challengerSnapshot.docs.length} documents');
        print('📦 Opponent query: ${opponentSnapshot.docs.length} documents');
      }
      
      final allChallenges = <String, ChallengeModel>{};
      
      // Add challenger challenges
      for (var doc in challengerSnapshot.docs) {
        try {
          final challenge = ChallengeModel.fromFirestore(doc);
          allChallenges[challenge.id] = challenge;
          if (kDebugMode) {
            print('  ✓ Added challenger challenge: ${challenge.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ❌ Error parsing challenger challenge ${doc.id}: $e');
          }
        }
      }
      
      // Add opponent challenges
      for (var doc in opponentSnapshot.docs) {
        try {
          final challenge = ChallengeModel.fromFirestore(doc);
          allChallenges[challenge.id] = challenge;
          if (kDebugMode) {
            print('  ✓ Added opponent challenge: ${challenge.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ❌ Error parsing opponent challenge ${doc.id}: $e');
          }
        }
      }
      
      final challenges = allChallenges.values.toList();
      challenges.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      if (kDebugMode) {
        print('✅ Returning ${challenges.length} total challenges');
      }
      
      return challenges;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting all challenges: $e');
      return [];
    }
  }
}


