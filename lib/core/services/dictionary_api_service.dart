import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DictionaryApiService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  
  /// Fetch word data from Free Dictionary API
  static Future<DictionaryWordData?> fetchWordData(String word) async {
    try {
      final url = Uri.parse('$_baseUrl/${word.toLowerCase().trim()}');
      
      if (kDebugMode) {
        print('🔍 Fetching dictionary data for: $word');
        print('📡 URL: $url');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final wordData = data[0] as Map<String, dynamic>;
          return DictionaryWordData.fromJson(wordData);
        }
      } else {
        if (kDebugMode) {
          print('❌ Dictionary API Error: ${response.statusCode}');
          print('Response: ${response.body}');
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching dictionary data: $e');
      }
      return null;
    }
  }
}

class DictionaryWordData {
  final String word;
  final String phonetic;
  final List<DictionaryMeaning> meanings;
  final List<DictionaryPhonetic> phonetics;
  
  DictionaryWordData({
    required this.word,
    required this.phonetic,
    required this.meanings,
    required this.phonetics,
  });
  
  factory DictionaryWordData.fromJson(Map<String, dynamic> json) {
    return DictionaryWordData(
      word: json['word'] ?? '',
      phonetic: json['phonetic'] ?? '',
      meanings: (json['meanings'] as List?)
          ?.map((m) => DictionaryMeaning.fromJson(m))
          .toList() ?? [],
      phonetics: (json['phonetics'] as List?)
          ?.map((p) => DictionaryPhonetic.fromJson(p))
          .toList() ?? [],
    );
  }
  
  /// Get primary definition (first noun/verb definition)
  String get primaryDefinition {
    for (var meaning in meanings) {
      if (meaning.definitions.isNotEmpty) {
        return meaning.definitions.first.definition;
      }
    }
    return '';
  }
  
  /// Get part of speech (prioritize noun/verb)
  String get primaryPartOfSpeech {
    const priorityOrder = ['noun', 'verb', 'adjective', 'adverb'];
    
    for (var pos in priorityOrder) {
      for (var meaning in meanings) {
        if (meaning.partOfSpeech.toLowerCase() == pos) {
          return meaning.partOfSpeech;
        }
      }
    }
    
    return meanings.isNotEmpty ? meanings.first.partOfSpeech : 'noun';
  }
  
  /// Get examples from all meanings
  List<String> get allExamples {
    List<String> examples = [];
    
    for (var meaning in meanings) {
      for (var definition in meaning.definitions) {
        if (definition.example.isNotEmpty) {
          examples.add(definition.example);
        }
      }
    }
    
    return examples.take(3).toList(); // Limit to 3 examples
  }
  
  /// Get synonyms from all meanings
  List<String> get allSynonyms {
    Set<String> synonyms = {};
    
    for (var meaning in meanings) {
      synonyms.addAll(meaning.synonyms);
      for (var definition in meaning.definitions) {
        synonyms.addAll(definition.synonyms);
      }
    }
    
    return synonyms.take(5).toList(); // Limit to 5 synonyms
  }
  
  /// Get antonyms from all meanings
  List<String> get allAntonyms {
    Set<String> antonyms = {};
    
    for (var meaning in meanings) {
      antonyms.addAll(meaning.antonyms);
      for (var definition in meaning.definitions) {
        antonyms.addAll(definition.antonyms);
      }
    }
    
    return antonyms.take(5).toList(); // Limit to 5 antonyms
  }
  
  /// Get best audio URL
  String? get bestAudioUrl {
    // Try to find audio from phonetics
    for (var phonetic in phonetics) {
      if (phonetic.audio.isNotEmpty) {
        return phonetic.audio;
      }
    }
    return null;
  }
  
  /// Get best pronunciation text
  String get bestPhonetic {
    if (phonetic.isNotEmpty) return phonetic;
    
    for (var p in phonetics) {
      if (p.text.isNotEmpty) {
        return p.text;
      }
    }
    
    return '';
  }
}

class DictionaryMeaning {
  final String partOfSpeech;
  final List<DictionaryDefinition> definitions;
  final List<String> synonyms;
  final List<String> antonyms;
  
  DictionaryMeaning({
    required this.partOfSpeech,
    required this.definitions,
    required this.synonyms,
    required this.antonyms,
  });
  
  factory DictionaryMeaning.fromJson(Map<String, dynamic> json) {
    return DictionaryMeaning(
      partOfSpeech: json['partOfSpeech'] ?? '',
      definitions: (json['definitions'] as List?)
          ?.map((d) => DictionaryDefinition.fromJson(d))
          .toList() ?? [],
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
    );
  }
}

class DictionaryDefinition {
  final String definition;
  final String example;
  final List<String> synonyms;
  final List<String> antonyms;
  
  DictionaryDefinition({
    required this.definition,
    required this.example,
    required this.synonyms,
    required this.antonyms,
  });
  
  factory DictionaryDefinition.fromJson(Map<String, dynamic> json) {
    return DictionaryDefinition(
      definition: json['definition'] ?? '',
      example: json['example'] ?? '',
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
    );
  }
}

class DictionaryPhonetic {
  final String text;
  final String audio;
  
  DictionaryPhonetic({
    required this.text,
    required this.audio,
  });
  
  factory DictionaryPhonetic.fromJson(Map<String, dynamic> json) {
    return DictionaryPhonetic(
      text: json['text'] ?? '',
      audio: json['audio'] ?? '',
    );
  }
} 