import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String category;
  final int difficultyLevel; // 1-5
  final int duration; // in seconds
  final List<String> tags;
  final List<String> subtitles;
  final String? transcript;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isPremium;
  final int viewCount;
  final double rating;
  final int ratingCount;
  final Map<String, dynamic> metadata;
  final String createdBy; // user ID who created/uploaded
  final List<VideoChapter> chapters;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.category,
    required this.difficultyLevel,
    required this.duration,
    required this.tags,
    required this.subtitles,
    this.transcript,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.isPremium,
    required this.viewCount,
    required this.rating,
    required this.ratingCount,
    required this.metadata,
    required this.createdBy,
    required this.chapters,
  });

  // Factory constructor from Firestore document
  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return VideoModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      category: data['category'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? 1,
      duration: data['duration'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      subtitles: List<String>.from(data['subtitles'] ?? []),
      transcript: data['transcript'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      isPremium: data['isPremium'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdBy: data['createdBy'] ?? '',
      chapters: (data['chapters'] as List<dynamic>? ?? [])
          .map((chapter) => VideoChapter.fromMap(chapter))
          .toList(),
    );
  }

  // Factory constructor from Map
  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      category: map['category'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      duration: map['duration'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      subtitles: List<String>.from(map['subtitles'] ?? []),
      transcript: map['transcript'],
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
      viewCount: map['viewCount'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdBy: map['createdBy'] ?? '',
      chapters: (map['chapters'] as List<dynamic>? ?? [])
          .map((chapter) => VideoChapter.fromMap(chapter))
          .toList(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'duration': duration,
      'tags': tags,
      'subtitles': subtitles,
      'transcript': transcript,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'isPremium': isPremium,
      'viewCount': viewCount,
      'rating': rating,
      'ratingCount': ratingCount,
      'metadata': metadata,
      'createdBy': createdBy,
      'chapters': chapters.map((chapter) => chapter.toMap()).toList(),
    };
  }

  // Copy with method
  VideoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    String? category,
    int? difficultyLevel,
    int? duration,
    List<String>? tags,
    List<String>? subtitles,
    String? transcript,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPremium,
    int? viewCount,
    double? rating,
    int? ratingCount,
    Map<String, dynamic>? metadata,
    String? createdBy,
    List<VideoChapter>? chapters,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      subtitles: subtitles ?? this.subtitles,
      transcript: transcript ?? this.transcript,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPremium: isPremium ?? this.isPremium,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      chapters: chapters ?? this.chapters,
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
    int minutes = (duration / 60).floor();
    int seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get average rating
  double get averageRating => ratingCount > 0 ? rating / ratingCount : 0.0;

  // Check if video has chapters
  bool get hasChapters => chapters.isNotEmpty;

  // Check if video has subtitles
  bool get hasSubtitles => subtitles.isNotEmpty;

  // Check if video has transcript
  bool get hasTranscript => transcript != null && transcript!.isNotEmpty;

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, category: $category, difficultyLevel: $difficultyLevel, duration: $formattedDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VideoModel &&
        other.id == id &&
        other.title == title &&
        other.videoUrl == videoUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        videoUrl.hashCode;
  }
}

// Video Chapter Model
class VideoChapter {
  final String title;
  final int startTime; // in seconds
  final int endTime; // in seconds
  final String? description;

  VideoChapter({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
  });

  factory VideoChapter.fromMap(Map<String, dynamic> map) {
    return VideoChapter(
      title: map['title'] ?? '',
      startTime: map['startTime'] ?? 0,
      endTime: map['endTime'] ?? 0,
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
    };
  }

  // Get chapter duration
  int get duration => endTime - startTime;

  // Get formatted chapter duration
  String get formattedDuration {
    int minutes = (duration / 60).floor();
    int seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get formatted start time
  String get formattedStartTime {
    int minutes = (startTime / 60).floor();
    int seconds = startTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'VideoChapter(title: $title, startTime: $formattedStartTime, duration: $formattedDuration)';
  }
} 