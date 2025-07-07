import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularyModel {
  final String id;
  final String word;
  final String pronunciation;
  final String meaning;
  final String? definition;
  final List<String> examples;
  final String? imageUrl;
  final String? audioUrl;
  final String category;
  final int difficultyLevel; // 1-5
  final List<String> synonyms;
  final List<String> antonyms;
  final String partOfSpeech; // noun, verb, adjective, etc.
  final List<String> lessonIds; // Lessons this word appears in
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int usageCount;
  final Map<String, dynamic> metadata;

  VocabularyModel({
    required this.id,
    required this.word,
    required this.pronunciation,
    required this.meaning,
    this.definition,
    required this.examples,
    this.imageUrl,
    this.audioUrl,
    required this.category,
    required this.difficultyLevel,
    required this.synonyms,
    required this.antonyms,
    required this.partOfSpeech,
    required this.lessonIds,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.usageCount,
    required this.metadata,
  });

  // Factory constructor from Firestore document
  factory VocabularyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return VocabularyModel(
      id: doc.id,
      word: data['word'] ?? '',
      pronunciation: data['pronunciation'] ?? '',
      meaning: data['meaning'] ?? '',
      definition: data['definition'],
      examples: List<String>.from(data['examples'] ?? []),
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
      category: data['category'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? 1,
      synonyms: List<String>.from(data['synonyms'] ?? []),
      antonyms: List<String>.from(data['antonyms'] ?? []),
      partOfSpeech: data['partOfSpeech'] ?? '',
      lessonIds: List<String>.from(data['lessonIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      usageCount: data['usageCount'] ?? 0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Factory constructor from Map
  factory VocabularyModel.fromMap(Map<String, dynamic> map) {
    return VocabularyModel(
      id: map['id'] ?? '',
      word: map['word'] ?? '',
      pronunciation: map['pronunciation'] ?? '',
      meaning: map['meaning'] ?? '',
      definition: map['definition'],
      examples: List<String>.from(map['examples'] ?? []),
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      category: map['category'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      synonyms: List<String>.from(map['synonyms'] ?? []),
      antonyms: List<String>.from(map['antonyms'] ?? []),
      partOfSpeech: map['partOfSpeech'] ?? '',
      lessonIds: List<String>.from(map['lessonIds'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
      isActive: map['isActive'] ?? true,
      usageCount: map['usageCount'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'pronunciation': pronunciation,
      'meaning': meaning,
      'definition': definition,
      'examples': examples,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'partOfSpeech': partOfSpeech,
      'lessonIds': lessonIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'usageCount': usageCount,
      'metadata': metadata,
    };
  }

  // Copy with method
  VocabularyModel copyWith({
    String? id,
    String? word,
    String? pronunciation,
    String? meaning,
    String? definition,
    List<String>? examples,
    String? imageUrl,
    String? audioUrl,
    String? category,
    int? difficultyLevel,
    List<String>? synonyms,
    List<String>? antonyms,
    String? partOfSpeech,
    List<String>? lessonIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? usageCount,
    Map<String, dynamic>? metadata,
  }) {
    return VocabularyModel(
      id: id ?? this.id,
      word: word ?? this.word,
      pronunciation: pronunciation ?? this.pronunciation,
      meaning: meaning ?? this.meaning,
      definition: definition ?? this.definition,
      examples: examples ?? this.examples,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      lessonIds: lessonIds ?? this.lessonIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
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

  // Get Vietnamese difficulty name
  String get vietnameseDifficultyName {
    switch (difficultyLevel) {
      case 1:
        return 'Cơ bản';
      case 2:
        return 'Sơ cấp';
      case 3:
        return 'Trung cấp';
      case 4:
        return 'Trung cấp cao';
      case 5:
        return 'Nâng cao';
      default:
        return 'Cơ bản';
    }
  }

  // Check if word has multimedia content
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasMultimedia => hasImage || hasAudio;

  // Get formatted word with part of speech
  String get wordWithPartOfSpeech {
    if (partOfSpeech.isNotEmpty) {
      return '$word ($partOfSpeech)';
    }
    return word;
  }

  // Get Vietnamese part of speech
  String get vietnamesePartOfSpeech {
    switch (partOfSpeech.toLowerCase()) {
      case 'noun':
        return 'Danh từ';
      case 'verb':
        return 'Động từ';
      case 'adjective':
        return 'Tính từ';
      case 'adverb':
        return 'Trạng từ';
      case 'preposition':
        return 'Giới từ';
      case 'conjunction':
        return 'Liên từ';
      case 'interjection':
        return 'Thán từ';
      case 'pronoun':
        return 'Đại từ';
      default:
        return partOfSpeech;
    }
  }

  // Check if auto-generated from lesson
  bool get isAutoGenerated => metadata['auto_generated'] == true;

  // Get lesson count
  int get lessonCount => lessonIds.length;

  @override
  String toString() {
    return 'VocabularyModel(id: $id, word: $word, meaning: $meaning, category: $category, difficultyLevel: $difficultyLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VocabularyModel &&
        other.id == id &&
        other.word == word &&
        other.meaning == meaning;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        word.hashCode ^
        meaning.hashCode;
  }
} 