import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TranslationService {
  // Using MyMemory Translation API (free)
  static const String _translateBaseUrl = 'https://api.mymemory.translated.net/get';
  
  /// Translate English to Vietnamese
  static Future<String?> translateToVietnamese(String englishText) async {
    try {
      if (englishText.trim().isEmpty) return null;
      
      final url = Uri.parse('$_translateBaseUrl?q=${Uri.encodeComponent(englishText)}&langpair=en|vi');
      
      if (kDebugMode) {
        print('🌐 Translating: $englishText');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['responseData']['translatedText'] as String?;
        
        if (translatedText != null && translatedText.isNotEmpty) {
          if (kDebugMode) {
            print('✅ Translation: $translatedText');
          }
          return translatedText;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Translation error: $e');
      }
      return null;
    }
  }
  
  /// Auto-detect category from part of speech and word context
  static String detectCategory(String partOfSpeech, String word, String definition) {
    final pos = partOfSpeech.toLowerCase();
    final wordLower = word.toLowerCase();
    final defLower = definition.toLowerCase();
    
    // Grammar-related words
    if (pos == 'preposition' || pos == 'conjunction' || pos == 'pronoun' ||
        _isGrammarWord(wordLower) || _isGrammarDefinition(defLower)) {
      return 'Grammar';
    }
    
    // Speaking-related words
    if (_isSpeakingWord(wordLower) || _isSpeakingDefinition(defLower)) {
      return 'Speaking';
    }
    
    // Listening-related words
    if (_isListeningWord(wordLower) || _isListeningDefinition(defLower)) {
      return 'Listening';
    }
    
    // Writing-related words
    if (_isWritingWord(wordLower) || _isWritingDefinition(defLower)) {
      return 'Writing';
    }
    
    // Default to Vocabulary for most words
    return 'Vocabulary';
  }
  
  static bool _isGrammarWord(String word) {
    const grammarWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'because', 'although', 'however',
      'therefore', 'moreover', 'furthermore', 'nevertheless', 'meanwhile',
      'about', 'above', 'across', 'after', 'against', 'along', 'among',
      'around', 'at', 'before', 'behind', 'below', 'beneath', 'beside',
      'between', 'beyond', 'by', 'during', 'except', 'for', 'from',
      'in', 'inside', 'into', 'like', 'near', 'of', 'off', 'on',
      'outside', 'over', 'since', 'through', 'throughout', 'till',
      'to', 'toward', 'under', 'until', 'up', 'upon', 'with', 'within',
      'without', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me',
      'him', 'her', 'us', 'them', 'my', 'your', 'his', 'its', 'our',
      'their', 'mine', 'yours', 'hers', 'ours', 'theirs'
    };
    return grammarWords.contains(word);
  }
  
  static bool _isGrammarDefinition(String definition) {
    const grammarKeywords = [
      'preposition', 'conjunction', 'pronoun', 'article', 'auxiliary',
      'modal', 'determiner', 'quantifier', 'grammatical', 'syntax'
    ];
    return grammarKeywords.any((keyword) => definition.contains(keyword));
  }
  
  static bool _isSpeakingWord(String word) {
    const speakingWords = {
      'say', 'speak', 'talk', 'tell', 'ask', 'answer', 'reply', 'respond',
      'discuss', 'explain', 'describe', 'express', 'communicate', 'conversation',
      'dialogue', 'interview', 'presentation', 'speech', 'voice', 'accent',
      'pronunciation', 'intonation', 'fluent', 'articulate', 'verbal'
    };
    return speakingWords.contains(word);
  }
  
  static bool _isSpeakingDefinition(String definition) {
    const speakingKeywords = [
      'speak', 'talk', 'say', 'oral', 'verbal', 'conversation', 'communication',
      'pronunciation', 'accent', 'dialogue', 'discussion'
    ];
    return speakingKeywords.any((keyword) => definition.contains(keyword));
  }
  
  static bool _isListeningWord(String word) {
    const listeningWords = {
      'hear', 'listen', 'sound', 'noise', 'music', 'song', 'audio',
      'recording', 'podcast', 'radio', 'broadcast', 'announcement',
      'volume', 'loud', 'quiet', 'silent', 'whisper', 'shout'
    };
    return listeningWords.contains(word);
  }
  
  static bool _isListeningDefinition(String definition) {
    const listeningKeywords = [
      'hear', 'listen', 'sound', 'audio', 'music', 'noise', 'recording',
      'broadcast', 'auditory'
    ];
    return listeningKeywords.any((keyword) => definition.contains(keyword));
  }
  
  static bool _isWritingWord(String word) {
    const writingWords = {
      'write', 'read', 'book', 'letter', 'email', 'text', 'document',
      'essay', 'story', 'novel', 'article', 'paragraph', 'sentence',
      'word', 'grammar', 'spelling', 'punctuation', 'pen', 'pencil',
      'paper', 'notebook', 'diary', 'journal', 'author', 'editor'
    };
    return writingWords.contains(word);
  }
  
  static bool _isWritingDefinition(String definition) {
    const writingKeywords = [
      'write', 'writing', 'written', 'text', 'document', 'literature',
      'composition', 'essay', 'article', 'spelling', 'grammar'
    ];
    return writingKeywords.any((keyword) => definition.contains(keyword));
  }
  
  /// Get Vietnamese part of speech name
  static String getVietnamesePartOfSpeech(String englishPos) {
    switch (englishPos.toLowerCase()) {
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
      case 'determiner':
        return 'Từ hạn định';
      case 'article':
        return 'Mạo từ';
      default:
        return englishPos;
    }
  }
} 