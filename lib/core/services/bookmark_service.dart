import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vocab_model.dart';

class BookmarkService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add vocabulary to bookmarks (different from favorites)
  static Future<bool> addVocabularyBookmark(String vocabularyId, {
    String? practiceType,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for bookmark');
        return false;
      }

      print('📌 Adding bookmark for vocabulary: $vocabularyId');
      print('👤 User ID: ${user.uid}');
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc('vocab_$vocabularyId')
          .set({
        'type': 'vocabulary',
        'itemId': vocabularyId,
        'practiceType': practiceType ?? 'flashcard',
        'notes': notes ?? '',
        'bookmarkedAt': FieldValue.serverTimestamp(),
        'needsReview': true,
        'reviewCount': 0,
        'lastReviewed': null,
      });

      print('✅ Bookmark added successfully');
      return true;
    } catch (e) {
      print('❌ Error adding vocabulary bookmark: $e');
      return false;
    }
  }

  // Remove vocabulary bookmark
  static Future<bool> removeVocabularyBookmark(String vocabularyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc('vocab_$vocabularyId')
          .delete();

      return true;
    } catch (e) {
      print('Error removing vocabulary bookmark: $e');
      return false;
    }
  }

  // Check if vocabulary is bookmarked
  static Future<bool> isVocabularyBookmarked(String vocabularyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc('vocab_$vocabularyId')
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking vocabulary bookmark: $e');
      return false;
    }
  }

  // Get all bookmarked vocabularies
  static Future<List<VocabularyModel>> getBookmarkedVocabularies() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final bookmarksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .where('type', isEqualTo: 'vocabulary')
          .orderBy('bookmarkedAt', descending: true)
          .get();

      List<VocabularyModel> bookmarkedVocabularies = [];

      for (var doc in bookmarksSnapshot.docs) {
        String vocabularyId = doc.data()['itemId'];
        
        try {
          final vocabDoc = await _firestore
              .collection('vocabulary')
              .doc(vocabularyId)
              .get();
          
          if (vocabDoc.exists) {
            bookmarkedVocabularies.add(VocabularyModel.fromFirestore(vocabDoc));
          }
        } catch (e) {
          print('Error loading vocabulary $vocabularyId: $e');
        }
      }

      return bookmarkedVocabularies;
    } catch (e) {
      print('Error getting bookmarked vocabularies: $e');
      return [];
    }
  }

  // Get bookmarks that need review
  static Future<List<VocabularyModel>> getVocabulariesNeedingReview() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final bookmarksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .where('type', isEqualTo: 'vocabulary')
          .where('needsReview', isEqualTo: true)
          .orderBy('bookmarkedAt', descending: true)
          .get();

      List<VocabularyModel> needReviewVocabularies = [];

      for (var doc in bookmarksSnapshot.docs) {
        String vocabularyId = doc.data()['itemId'];
        
        try {
          final vocabDoc = await _firestore
              .collection('vocabulary')
              .doc(vocabularyId)
              .get();
          
          if (vocabDoc.exists) {
            needReviewVocabularies.add(VocabularyModel.fromFirestore(vocabDoc));
          }
        } catch (e) {
          print('Error loading vocabulary $vocabularyId: $e');
        }
      }

      return needReviewVocabularies;
    } catch (e) {
      print('Error getting vocabularies needing review: $e');
      return [];
    }
  }

  // Mark bookmark as reviewed
  static Future<bool> markAsReviewed(String vocabularyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc('vocab_$vocabularyId')
          .update({
        'needsReview': false,
        'reviewCount': FieldValue.increment(1),
        'lastReviewed': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error marking as reviewed: $e');
      return false;
    }
  }

  // Toggle vocabulary bookmark status
  static Future<bool> toggleVocabularyBookmark(String vocabularyId, {
    String? practiceType,
    String? notes,
  }) async {
    final isBookmarked = await isVocabularyBookmarked(vocabularyId);
    
    if (isBookmarked) {
      return await removeVocabularyBookmark(vocabularyId);
    } else {
      return await addVocabularyBookmark(
        vocabularyId,
        practiceType: practiceType,
        notes: notes,
      );
    }
  }

  // Get bookmark count
  static Future<int> getBookmarkCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .where('type', isEqualTo: 'vocabulary')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting bookmark count: $e');
      return 0;
    }
  }

  // Get bookmark statistics
  static Future<Map<String, dynamic>> getBookmarkStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .where('type', isEqualTo: 'vocabulary')
          .get();

      int total = snapshot.docs.length;
      int needingReview = 0;
      int reviewed = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['needsReview'] == true) {
          needingReview++;
        } else {
          reviewed++;
        }
      }

      return {
        'total': total,
        'needingReview': needingReview,
        'reviewed': reviewed,
        'reviewRate': total > 0 ? (reviewed / total * 100).round() : 0,
      };
    } catch (e) {
      print('Error getting bookmark stats: $e');
      return {};
    }
  }
} 