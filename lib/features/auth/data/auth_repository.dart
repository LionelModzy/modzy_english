import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/user_model.dart';

class AuthRepository {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential? userCredential = await FirebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential != null && userCredential.user != null) {
        // Get user data from Firestore to check account status
        final userDoc = await FirebaseService.getUserDocument(userCredential.user!.uid);
        
        if (userDoc.exists) {
          final userData = UserModel.fromFirestore(userDoc);
          
          // Check if user account is active
          if (!userData.isActive) {
            // Sign out the user immediately
            await FirebaseService.signOut();
            Fluttertoast.showToast(
              msg: 'Tài khoản của bạn đã bị tạm dừng. Vui lòng liên hệ quản trị viên.',
              toastLength: Toast.LENGTH_LONG,
            );
            throw Exception('Tài khoản đã bị tạm dừng');
          }
          
          // Update last login time only if account is active
          await FirebaseService.updateUserDocument(
            uid: userCredential.user!.uid,
            userData: {
              'lastLoginAt': DateTime.now(),
            },
          );

          return userData;
        }
      }
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      throw Exception(e.toString());
    }
  }

  // Register with email and password
  static Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential? userCredential = await FirebaseService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential != null && userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Create user document in Firestore
        UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: 'user',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          preferences: {},
          totalLessonsCompleted: 0,
          totalVocabularyLearned: 0,
          currentLevel: 1,
          progressPercentage: 0.0,
        );

        await FirebaseService.createUserDocument(
          uid: userCredential.user!.uid,
          userData: userModel.toMap(),
        );

        Fluttertoast.showToast(msg: 'Account created successfully!');
        return userModel;
      }
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      throw Exception(e.toString());
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await FirebaseService.signOut();
      Fluttertoast.showToast(msg: 'Signed out successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error signing out: $e');
      throw Exception(e.toString());
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseService.sendPasswordResetEmail(email);
      Fluttertoast.showToast(msg: 'Password reset email sent!');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      throw Exception(e.toString());
    }
  }

  // Get current user data
  static Future<UserModel?> getCurrentUserData() async {
    try {
      User? user = currentUser;
      if (user != null) {
        final userDoc = await FirebaseService.getUserDocument(user.uid);
        if (userDoc.exists) {
          final userData = UserModel.fromFirestore(userDoc);
          
          // Check if user account is still active
          if (!userData.isActive) {
            // Sign out the user if account has been deactivated
            await signOut();
            Fluttertoast.showToast(
              msg: 'Tài khoản của bạn đã bị tạm dừng. Vui lòng liên hệ quản trị viên.',
              toastLength: Toast.LENGTH_LONG,
            );
            return null;
          }
          
          return userData;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user data: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (displayName != null) {
        updateData['displayName'] = displayName;
        // Also update Firebase Auth display name
        await currentUser?.updateDisplayName(displayName);
      }
      
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
        // Also update Firebase Auth photo URL
        await currentUser?.updatePhotoURL(profileImageUrl);
      }
      
      if (preferences != null) {
        updateData['preferences'] = preferences;
      }

      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = DateTime.now();
        await FirebaseService.updateUserDocument(
          uid: uid,
          userData: updateData,
        );
      }

      Fluttertoast.showToast(msg: 'Profile updated successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating profile: $e');
      throw Exception(e.toString());
    }
  }

  // Update user progress
  static Future<void> updateUserProgress({
    required String uid,
    int? totalLessonsCompleted,
    int? totalVocabularyLearned,
    int? currentLevel,
    double? progressPercentage,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (totalLessonsCompleted != null) {
        updateData['totalLessonsCompleted'] = totalLessonsCompleted;
      }
      
      if (totalVocabularyLearned != null) {
        updateData['totalVocabularyLearned'] = totalVocabularyLearned;
      }
      
      if (currentLevel != null) {
        updateData['currentLevel'] = currentLevel;
      }
      
      if (progressPercentage != null) {
        updateData['progressPercentage'] = progressPercentage;
      }

      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = DateTime.now();
        await FirebaseService.updateUserDocument(
          uid: uid,
          userData: updateData,
        );
      }
    } catch (e) {
      throw Exception('Error updating user progress: $e');
    }
  }

  // Delete user account
  static Future<void> deleteAccount() async {
    try {
      User? user = currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await FirebaseService.deleteDocument(
          collection: 'users',
          docId: user.uid,
        );
        
        // Delete Firebase Auth account
        await user.delete();
        
        Fluttertoast.showToast(msg: 'Account deleted successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting account: $e');
      throw Exception(e.toString());
    }
  }

  // Check if user is admin
  static Future<bool> isAdmin() async {
    try {
      UserModel? user = await getCurrentUserData();
      return user?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  // Reload current user
  static Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      throw Exception('Error reloading user: $e');
    }
  }

  // Check if email is verified
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
      Fluttertoast.showToast(msg: 'Verification email sent!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sending verification email: $e');
      throw Exception(e.toString());
    }
  }
} 