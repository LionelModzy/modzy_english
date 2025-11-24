import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import 'friend_service.dart';

enum FriendRequestActionResult {
  sent,
  alreadyFriends,
  alreadyPending,
  incomingPending,
  userNotFound,
  selfNotAllowed,
  failure,
}

class FriendRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'friend_requests';

  static CollectionReference get _collectionRef => _firestore.collection(_collection);

  static Future<FriendRequestActionResult> sendRequest({
    required UserModel sender,
    required UserModel receiver,
  }) async {
    if (sender.uid == receiver.uid) {
      return FriendRequestActionResult.selfNotAllowed;
    }

    final alreadyFriends = await FriendService.areFriends(
      userId: sender.uid,
      friendUserId: receiver.uid,
    );
    if (alreadyFriends) {
      return FriendRequestActionResult.alreadyFriends;
    }

    try {
      // Check if there's already a pending request from sender to receiver
      final existing = await _collectionRef
          .where('senderId', isEqualTo: sender.uid)
          .where('receiverId', isEqualTo: receiver.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return FriendRequestActionResult.alreadyPending;
      }

      // Check if there's an incoming request from receiver to sender
      final incoming = await _collectionRef
          .where('senderId', isEqualTo: receiver.uid)
          .where('receiverId', isEqualTo: sender.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (incoming.docs.isNotEmpty) {
        return FriendRequestActionResult.incomingPending;
      }

      await _collectionRef.add({
        'senderId': sender.uid,
        'senderName': sender.displayName,
        'senderAvatar': sender.profileImageUrl,
        'receiverId': receiver.uid,
        'receiverName': receiver.displayName,
        'receiverAvatar': receiver.profileImageUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': [sender.uid, receiver.uid],
      });

      return FriendRequestActionResult.sent;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending friend request: $e');
      }
      return FriendRequestActionResult.failure;
    }
  }

  static Stream<List<FriendRequestModel>> watchRequests(String userId) {
    // Use two separate queries to avoid arrayContains permission issues
    // Query 1: Where user is sender
    final senderStream = _collectionRef
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
    
    // Query 2: Where user is receiver
    final receiverStream = _collectionRef
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
    
    // Combine both streams using StreamController
    final controller = StreamController<List<FriendRequestModel>>();
    final allDocs = <String, FriendRequestModel>{};
    
    void emitMerged() {
      final result = allDocs.values.toList();
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(result);
    }
    
    StreamSubscription? senderSub;
    StreamSubscription? receiverSub;
    
    senderSub = senderStream.listen((snapshot) {
      for (var doc in snapshot.docs) {
        allDocs[doc.id] = FriendRequestModel.fromFirestore(doc);
      }
      emitMerged();
    });
    
    receiverSub = receiverStream.listen((snapshot) {
      for (var doc in snapshot.docs) {
        allDocs[doc.id] = FriendRequestModel.fromFirestore(doc);
      }
      emitMerged();
    });
    
    controller.onCancel = () {
      senderSub?.cancel();
      receiverSub?.cancel();
    };
    
    return controller.stream;
  }

  static Future<bool> cancelRequest(FriendRequestModel request, {required String userId}) async {
    if (request.senderId != userId) return false;
    if (!request.isPending) return false;

    try {
      await _collectionRef.doc(request.id).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling friend request: $e');
      }
      return false;
    }
  }

  static Future<bool> respondToRequest({
    required FriendRequestModel request,
    required String userId,
    required bool accept,
  }) async {
    if (request.receiverId != userId) return false;
    if (!request.isPending) return false;

    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _collectionRef.doc(request.id);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Request no longer exists');
        }
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['status'] != 'pending') return;

        transaction.update(docRef, {
          'status': accept ? 'accepted' : 'declined',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (accept) {
        await FriendService.linkFriends(
          currentUserId: request.senderId,
          friendUserId: request.receiverId,
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error responding to friend request: $e');
      }
      return false;
    }
  }
}

