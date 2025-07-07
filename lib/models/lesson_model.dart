import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String category;
  final int difficultyLevel; // 1-5
  final int estimatedDuration; // in minutes
  final List<String> tags;
  final List<String> objectives; // Learning objectives
  final String? audioUrl;
  final String? imageUrl;
  final String? videoUrl; // Main lesson video
  final List<LessonSection> sections;
  final List<String> vocabulary; // Vocabulary words used in lesson
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isPremium;
  final int order; // Order in curriculum
  final String createdBy;
  final Map<String, dynamic> metadata;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.difficultyLevel,
    required this.estimatedDuration,
    required this.tags,
    required this.objectives,
    this.audioUrl,
    this.imageUrl,
    this.videoUrl,
    required this.sections,
    required this.vocabulary,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.isPremium,
    required this.order,
    required this.createdBy,
    required this.metadata,
  });

  // Factory constructor from Firestore document
  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return LessonModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? 1,
      estimatedDuration: data['estimatedDuration'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      objectives: List<String>.from(data['objectives'] ?? []),
      audioUrl: data['audioUrl'],
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      sections: (data['sections'] as List<dynamic>? ?? [])
          .map((section) => LessonSection.fromMap(section))
          .toList(),
      vocabulary: List<String>.from(data['vocabulary'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      isPremium: data['isPremium'] ?? false,
      order: data['order'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Factory constructor from Map
  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      estimatedDuration: map['estimatedDuration'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      objectives: List<String>.from(map['objectives'] ?? []),
      audioUrl: map['audioUrl'],
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      sections: (map['sections'] as List<dynamic>? ?? [])
          .map((section) => LessonSection.fromMap(section))
          .toList(),
      vocabulary: List<String>.from(map['vocabulary'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
      isActive: map['isActive'] ?? true,
      isPremium: map['isPremium'] ?? false,
      order: map['order'] ?? 0,
      createdBy: map['createdBy'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'estimatedDuration': estimatedDuration,
      'tags': tags,
      'objectives': objectives,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'sections': sections.map((section) => section.toMap()).toList(),
      'vocabulary': vocabulary,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'isPremium': isPremium,
      'order': order,
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  // Copy with method
  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? category,
    int? difficultyLevel,
    int? estimatedDuration,
    List<String>? tags,
    List<String>? objectives,
    String? audioUrl,
    String? imageUrl,
    String? videoUrl,
    List<LessonSection>? sections,
    List<String>? vocabulary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPremium,
    int? order,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      tags: tags ?? this.tags,
      objectives: objectives ?? this.objectives,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      sections: sections ?? this.sections,
      vocabulary: vocabulary ?? this.vocabulary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPremium: isPremium ?? this.isPremium,
      order: order ?? this.order,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get difficulty level name
  String get difficultyLevelName {
    switch (difficultyLevel) {
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

  // Get formatted duration
  String get formattedDuration {
    if (estimatedDuration < 60) {
      return '${estimatedDuration}m';
    } else {
      int hours = estimatedDuration ~/ 60;
      int minutes = estimatedDuration % 60;
      return '${hours}h ${minutes}m';
    }
  }

  // Check if lesson has audio
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  // Check if lesson has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // Check if lesson has video
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  // Check if lesson has sections
  bool get hasSections => sections.isNotEmpty;

  @override
  String toString() {
    return 'LessonModel(id: $id, title: $title, category: $category, difficultyLevel: $difficultyLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LessonModel &&
        other.id == id &&
        other.title == title;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode;
  }
}

// Lesson Section Model
class LessonSection {
  final String title;
  final String content;
  final String type; // text, audio, video, exercise
  final String? mediaUrl;
  final Map<String, dynamic> metadata;

  LessonSection({
    required this.title,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.metadata,
  });

  factory LessonSection.fromMap(Map<String, dynamic> map) {
    return LessonSection(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
      'metadata': metadata,
    };
  }

  // Check if section has media
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  @override
  String toString() {
    return 'LessonSection(title: $title, type: $type)';
  }
} 