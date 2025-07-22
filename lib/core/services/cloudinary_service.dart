import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

enum CloudinaryFolder {
  profileImages('profile_images'),
  lessonImages('lesson_images'),
  lessonVideos('lesson_videos'),
  lessonAudio('lesson_audio'),
  userContent('user_content'),
  thumbnails('thumbnails');

  const CloudinaryFolder(this.folderName);
  final String folderName;
}

class CloudinaryUploadResult {
  final bool success;
  final String? url;
  final String? secureUrl;
  final String? publicId;
  final String? folder;
  final String? error;
  final Map<String, dynamic>? metadata;
  
  CloudinaryUploadResult({
    required this.success,
    this.url,
    this.secureUrl,
    this.publicId,
    this.folder,
    this.error,
    this.metadata,
  });
  
  String? get optimizedUrl => secureUrl ?? url;
}

class CloudinaryService {
  static const String _cloudName = 'dmn2x2mhb';
  static const String _apiKey = '539185966639123';
  static const String _apiSecret = 's6hRa8tepRqE92r_wSagW4Z2xFA';
  static const String _uploadPreset = 'modzy_upload';

  /// Upload image directly to Cloudinary with progress tracking
  static Future<CloudinaryUploadResult> uploadImage({
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    required CloudinaryFolder folder,
    String? customPublicId,
    Function(double progress)? onProgress,
  }) async {
    try {
      if (imageFile == null && imageBytes == null) {
        throw Exception('Either imageFile or imageBytes must be provided');
      }

      // Prepare form data
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Generate public ID - include folder in public_id to avoid duplication
      final publicId = customPublicId != null 
          ? '${folder.folderName}/$customPublicId'
          : '${folder.folderName}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Add fields - removed transformation parameters for unsigned upload
      request.fields.addAll({
        'upload_preset': _uploadPreset,
        'public_id': publicId,
        'resource_type': 'image',
      });

      // Add file
      if (kIsWeb && imageBytes != null) {
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName ?? 'upload.jpg',
        );
        request.files.add(multipartFile);
      } else if (imageFile != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: fileName ?? path.basename(imageFile.path),
        );
        request.files.add(multipartFile);
      }

      if (kDebugMode) {
        print('Uploading to Cloudinary: ${folder.folderName}/$publicId');
      }

      // Send request with progress tracking
      final streamedResponse = await request.send();
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseString = utf8.decode(responseBytes);
      
      if (streamedResponse.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseString);
        
        if (kDebugMode) {
          print('Cloudinary upload successful: ${responseData['secure_url']}');
        }
        
        return CloudinaryUploadResult(
          success: true,
          url: responseData['url'],
          secureUrl: responseData['secure_url'],
          publicId: responseData['public_id'],
          folder: folder.folderName,
          metadata: responseData,
        );
      } else {
        final errorData = json.decode(responseString);
        throw Exception('Upload failed: ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
      
    } catch (e) {
      if (kDebugMode) print('Cloudinary upload error: $e');
      return CloudinaryUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload video directly to Cloudinary
  static Future<CloudinaryUploadResult> uploadVideo({
    File? videoFile,
    Uint8List? videoBytes,
    String? fileName,
    required CloudinaryFolder folder,
    String? customPublicId,
    Function(double progress)? onProgress,
  }) async {
    try {
      if (videoFile == null && videoBytes == null) {
        throw Exception('Either videoFile or videoBytes must be provided');
      }

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload');
      final request = http.MultipartRequest('POST', uri);
      
      final publicId = customPublicId != null 
          ? '${folder.folderName}/$customPublicId'
          : '${folder.folderName}_${DateTime.now().millisecondsSinceEpoch}';
      
      request.fields.addAll({
        'upload_preset': _uploadPreset,
        'public_id': publicId,
        'resource_type': 'video',
      });

      // Add file
      if (kIsWeb && videoBytes != null) {
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          videoBytes,
          filename: fileName ?? 'upload.mp4',
        );
        request.files.add(multipartFile);
      } else if (videoFile != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          videoFile.path,
          filename: fileName ?? path.basename(videoFile.path),
        );
        request.files.add(multipartFile);
      }

      if (kDebugMode) {
        print('Uploading video to Cloudinary: ${folder.folderName}/$publicId');
      }

      final streamedResponse = await request.send();
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseString = utf8.decode(responseBytes);
      
      if (streamedResponse.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseString);
        
        if (kDebugMode) {
          print('Cloudinary video upload successful: ${responseData['secure_url']}');
        }
        
        return CloudinaryUploadResult(
          success: true,
          url: responseData['url'],
          secureUrl: responseData['secure_url'],
          publicId: responseData['public_id'],
          folder: folder.folderName,
          metadata: responseData,
        );
      } else {
        final errorData = json.decode(responseString);
        throw Exception('Video upload failed: ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
      
    } catch (e) {
      if (kDebugMode) print('Cloudinary video upload error: $e');
      return CloudinaryUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload audio directly to Cloudinary
  static Future<CloudinaryUploadResult> uploadAudio({
    File? audioFile,
    Uint8List? audioBytes,
    String? fileName,
    required CloudinaryFolder folder,
    String? customPublicId,
    Function(double progress)? onProgress,
  }) async {
    try {
      if (audioFile == null && audioBytes == null) {
        throw Exception('Either audioFile or audioBytes must be provided');
      }

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload');
      final request = http.MultipartRequest('POST', uri);
      
      final publicId = customPublicId != null 
          ? '${folder.folderName}/$customPublicId'
          : '${folder.folderName}_${DateTime.now().millisecondsSinceEpoch}';
      
      request.fields.addAll({
        'upload_preset': _uploadPreset,
        'public_id': publicId,
        'resource_type': 'video', // Audio files use video resource type in Cloudinary
      });

      // Add file
      if (kIsWeb && audioBytes != null) {
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: fileName ?? 'upload.mp3',
        );
        request.files.add(multipartFile);
      } else if (audioFile != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
          filename: fileName ?? path.basename(audioFile.path),
        );
        request.files.add(multipartFile);
      }

      if (kDebugMode) {
        print('Uploading audio to Cloudinary: ${folder.folderName}/$publicId');
      }

      final streamedResponse = await request.send();
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseString = utf8.decode(responseBytes);
      
      if (streamedResponse.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseString);
        
        if (kDebugMode) {
          print('Cloudinary audio upload successful: ${responseData['secure_url']}');
        }
        
        return CloudinaryUploadResult(
          success: true,
          url: responseData['url'],
          secureUrl: responseData['secure_url'],
          publicId: responseData['public_id'],
          folder: folder.folderName,
          metadata: responseData,
        );
      } else {
        final errorData = json.decode(responseString);
        throw Exception('Audio upload failed: ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
      
    } catch (e) {
      if (kDebugMode) print('Cloudinary audio upload error: $e');
      return CloudinaryUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Delete file from Cloudinary
  static Future<bool> deleteFile({
    required String publicId,
    String resourceType = 'image',
  }) async {
    try {
      if (kDebugMode) {
        print('Attempting to delete Cloudinary file: $publicId (type: $resourceType)');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature({
        'public_id': publicId,
        'timestamp': timestamp,
      });

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/destroy');
      
      final response = await http.post(
        uri,
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      if (kDebugMode) {
        print('Delete response status: ${response.statusCode}');
        print('Delete response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final success = responseData['result'] == 'ok';
        if (kDebugMode) {
          print('Delete result: $success');
        }
        return success;
      } else {
        if (kDebugMode) {
          print('Delete failed with status: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Cloudinary delete error: $e');
      return false;
    }
  }

  /// Generate signature for authenticated requests
  static String _generateSignature(Map<String, String> params) {
    // Sort parameters
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    // Create query string
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    // Add API secret
    final stringToSign = '$queryString$_apiSecret';
    
    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Get optimized image URL with transformations
  static String getOptimizedImageUrl({
    required String publicId,
    int? width,
    int? height,
    String quality = 'auto:good',
    String format = 'auto',
  }) {
    final baseUrl = 'https://res.cloudinary.com/$_cloudName/image/upload';
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    final transformationString = transformations.join(',');
    return '$baseUrl/$transformationString/$publicId';
  }

  /// Get video thumbnail URL
  static String getVideoThumbnail({
    required String publicId,
    int? width,
    int? height,
    String format = 'jpg',
  }) {
    final baseUrl = 'https://res.cloudinary.com/$_cloudName/video/upload';
    final transformations = <String>['so_0']; // First frame
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('f_$format');
    
    final transformationString = transformations.join(',');
    return '$baseUrl/$transformationString/$publicId.$format';
  }
} 