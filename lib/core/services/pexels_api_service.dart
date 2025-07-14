import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PexelsApiService {
  static const String _apiKey = '4tiGrE9JzIty1veKXQ3Qi7chxtLs02FWPAwMMjoBCob3wdvj7kVtV0GF';
  static const String _baseUrl = 'https://api.pexels.com/v1';
  
  /// Search for images related to a word
  static Future<String?> searchImageForWord(String word) async {
    try {
      // Clean the word and create search query
      final searchQuery = _generateSearchQuery(word);
      final url = Uri.parse('$_baseUrl/search?query=$searchQuery&per_page=5&orientation=landscape');
      
      if (kDebugMode) {
        print('🖼️ Searching image for: $word');
        print('🔍 Search query: $searchQuery');
        print('📡 URL: $url');
      }
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List?;
        
        if (photos != null && photos.isNotEmpty) {
          // Get the first image with medium size
          final photo = photos[0];
          final imageUrl = photo['src']['medium'] as String?;
          
          if (kDebugMode) {
            print('✅ Found image: $imageUrl');
          }
          
          return imageUrl;
        }
      } else {
        if (kDebugMode) {
          print('❌ Pexels API Error: ${response.statusCode}');
          print('Response: ${response.body}');
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching image: $e');
      }
      return null;
    }
  }
  
  /// Generate appropriate search query for different words
  static String _generateSearchQuery(String word) {
    final cleanWord = word.toLowerCase().trim();
    
    // Map specific words to better search terms
    final Map<String, String> wordMappings = {
      // Abstract concepts
      'love': 'heart couple romance',
      'happiness': 'smile joy celebration',
      'freedom': 'bird flying sky',
      'success': 'celebration achievement',
      'failure': 'disappointed sad person',
      'hope': 'sunrise light bright',
      'fear': 'dark shadow scary',
      'anger': 'storm red clouds',
      'peace': 'calm nature zen',
      'wisdom': 'owl books knowledge',
      
      // Actions
      'run': 'person running sport',
      'walk': 'person walking path',
      'jump': 'person jumping active',
      'dance': 'people dancing party',
      'sing': 'person singing microphone',
      'read': 'person reading book',
      'write': 'person writing notebook',
      'study': 'student books learning',
      'work': 'office computer business',
      'sleep': 'bed pillow peaceful',
      
      // Objects
      'book': 'books library knowledge',
      'computer': 'laptop technology work',
      'phone': 'smartphone mobile device',
      'car': 'automobile vehicle transport',
      'house': 'home building architecture',
      'tree': 'nature forest green',
      'flower': 'beautiful flowers garden',
      'water': 'clear water nature',
      'fire': 'flames campfire warm',
      'food': 'delicious meal cooking',
      
      // Time
      'morning': 'sunrise dawn early',
      'evening': 'sunset golden hour',
      'night': 'dark stars moon',
      'day': 'bright sunny daytime',
      'year': 'calendar time seasons',
      'month': 'calendar planning time',
      'week': 'calendar schedule time',
      
      // Weather
      'rain': 'raindrops water weather',
      'sun': 'bright sunshine golden',
      'snow': 'white snowflakes winter',
      'wind': 'trees swaying nature',
      'storm': 'dark clouds lightning',
      
      // Colors
      'red': 'red color bright vibrant',
      'blue': 'blue sky ocean water',
      'green': 'green nature forest',
      'yellow': 'yellow sunshine bright',
      'black': 'black dark elegant',
      'white': 'white clean minimal',
      
      // Animals
      'cat': 'cute cat pet animal',
      'dog': 'friendly dog pet',
      'bird': 'beautiful bird flying',
      'fish': 'colorful fish water',
      'horse': 'majestic horse animal',
      
      // Body parts
      'hand': 'human hand gesture',
      'eye': 'human eye close-up',
      'face': 'human face portrait',
      'hair': 'beautiful hair person',
      
      // Family
      'mother': 'mother child family',
      'father': 'father child family',
      'child': 'happy child playing',
      'family': 'happy family together',
      'friend': 'friends together happy',
      
      // Education
      'school': 'classroom education learning',
      'teacher': 'teacher classroom education',
      'student': 'student studying books',
      'lesson': 'classroom learning education',
      'exam': 'test paper student',
      
      // Business
      'money': 'coins cash currency',
      'business': 'office meeting professional',
      'job': 'professional work office',
      'meeting': 'business meeting office',
      
      // Technology
      'internet': 'computer network technology',
      'email': 'laptop email communication',
      'website': 'computer screen web',
      'software': 'computer code programming',
      
      // Health
      'doctor': 'medical doctor hospital',
      'medicine': 'pills medical health',
      'hospital': 'medical building healthcare',
      'healthy': 'fitness exercise wellness',
      
      // Sports
      'football': 'soccer ball sport',
      'basketball': 'basketball sport game',
      'tennis': 'tennis racket sport',
      'swimming': 'pool water sport',
      
      // Travel
      'travel': 'suitcase airplane journey',
      'vacation': 'beach paradise relaxation',
      'hotel': 'luxury hotel building',
      'airplane': 'aircraft flying sky',
      'train': 'railway transport travel',
      
      // Food
      'breakfast': 'morning meal coffee',
      'lunch': 'delicious meal food',
      'dinner': 'evening meal restaurant',
      'coffee': 'coffee cup morning',
      'tea': 'tea cup relaxing',
    };
    
    // Return mapped query or original word
    return wordMappings[cleanWord] ?? cleanWord;
  }
  
  /// Get curated image for specific categories
  static Future<String?> getCuratedImageForCategory(String category) async {
    try {
      final url = Uri.parse('$_baseUrl/curated?per_page=10');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List?;
        
        if (photos != null && photos.isNotEmpty) {
          // Get a random image from curated photos
          final randomIndex = DateTime.now().millisecond % photos.length;
          final photo = photos[randomIndex];
          return photo['src']['medium'] as String?;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting curated image: $e');
      }
      return null;
    }
  }
} 