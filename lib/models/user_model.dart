import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final String role; // 'user' or 'admin'
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic> preferences;
  final int totalLessonsCompleted;
  final int totalVocabularyLearned;
  final int currentLevel;
  final double progressPercentage;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    required this.isActive,
    required this.preferences,
    required this.totalLessonsCompleted,
    required this.totalVocabularyLearned,
    required this.currentLevel,
    required this.progressPercentage,
  });

  // Factory constructor to create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null 
          ? (data['lastLoginAt'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] ?? true,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      totalLessonsCompleted: data['totalLessonsCompleted'] ?? 0,
      totalVocabularyLearned: data['totalVocabularyLearned'] ?? 0,
      currentLevel: data['currentLevel'] ?? 1,
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
    );
  }

  // Factory constructor to create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      role: map['role'] ?? 'user',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null
          ? (map['lastLoginAt'] is Timestamp 
              ? (map['lastLoginAt'] as Timestamp).toDate()
              : DateTime.parse(map['lastLoginAt']))
          : null,
      isActive: map['isActive'] ?? true,
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      totalLessonsCompleted: map['totalLessonsCompleted'] ?? 0,
      totalVocabularyLearned: map['totalVocabularyLearned'] ?? 0,
      currentLevel: map['currentLevel'] ?? 1,
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'preferences': preferences,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalVocabularyLearned': totalVocabularyLearned,
      'currentLevel': currentLevel,
      'progressPercentage': progressPercentage,
    };
  }

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? profileImageUrl,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
    int? totalLessonsCompleted,
    int? totalVocabularyLearned,
    int? currentLevel,
    double? progressPercentage,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      totalLessonsCompleted: totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalVocabularyLearned: totalVocabularyLearned ?? this.totalVocabularyLearned,
      currentLevel: currentLevel ?? this.currentLevel,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Check if user is regular user
  bool get isUser => role == 'user';

  // Get user level name
  String get levelName {
    switch (currentLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Elementary';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Upper Intermediate';
      case 5:
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }

  // Get profile completion percentage
  double get profileCompletionPercentage {
    int completedFields = 0;
    int totalFields = 4; // email, displayName, profileImageUrl, preferences

    if (email.isNotEmpty) completedFields++;
    if (displayName.isNotEmpty) completedFields++;
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) completedFields++;
    if (preferences.isNotEmpty) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, role: $role, currentLevel: $currentLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.role == role;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        role.hashCode;
  }
} 