import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }
  
  // Authentication methods
  static User? get currentUser => _auth.currentUser;
  
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Firestore methods
  static Future<void> createUserDocument({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }
  
  static Future<DocumentSnapshot> getUserDocument(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw Exception('Failed to get user document: $e');
    }
  }
  
  static Future<void> updateUserDocument({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(userData);
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }
  
  static Stream<QuerySnapshot> getCollection(String collectionName) {
    return _firestore.collection(collectionName).snapshots();
  }
  
  static Future<QuerySnapshot> getCollectionOnce(String collectionName) {
    return _firestore.collection(collectionName).get();
  }
  
  static Future<void> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).add(data);
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }
  
  static Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }
  
  static Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
  
  // Helper method to handle auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'The user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
} 