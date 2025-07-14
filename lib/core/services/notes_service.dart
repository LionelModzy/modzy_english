import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a note to a lesson
  static Future<String> addLessonNote({
    required String lessonId,
    required String content,
    String? sectionId,
    double? timestamp, // For video/audio notes
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final noteData = {
        'lessonId': lessonId,
        'userId': user.uid,
        'content': content,
        'sectionId': sectionId,
        'timestamp': timestamp,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      DocumentReference docRef = await _firestore
          .collection('lesson_notes')
          .add(noteData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  // Update an existing note
  static Future<void> updateNote(String noteId, String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('lesson_notes').doc(noteId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // Delete a note
  static Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection('lesson_notes').doc(noteId).delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // Get all notes for a lesson
  static Future<List<Map<String, dynamic>>> getLessonNotes(String lessonId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('lesson_notes')
          .where('lessonId', isEqualTo: lessonId)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch notes: $e');
    }
  }

  // Get notes for a specific section
  static Future<List<Map<String, dynamic>>> getSectionNotes(
    String lessonId, 
    String sectionId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('lesson_notes')
          .where('lessonId', isEqualTo: lessonId)
          .where('userId', isEqualTo: user.uid)
          .where('sectionId', isEqualTo: sectionId)
          .orderBy('timestamp')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch section notes: $e');
    }
  }

  // Get all user notes
  static Future<List<Map<String, dynamic>>> getAllUserNotes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('lesson_notes')
          .where('userId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user notes: $e');
    }
  }

  // Search notes
  static Future<List<Map<String, dynamic>>> searchNotes(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('lesson_notes')
          .where('userId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((note) => 
              note['content'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search notes: $e');
    }
  }

  // Get notes count for a lesson
  static Future<int> getLessonNotesCount(String lessonId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      QuerySnapshot snapshot = await _firestore
          .collection('lesson_notes')
          .where('lessonId', isEqualTo: lessonId)
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
} 