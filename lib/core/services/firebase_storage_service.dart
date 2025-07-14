import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'cloudinary_service.dart';

enum MediaFolder {
  profileImages('profile_images'),
  lessonImages('lesson_images'),
  lessonVideos('lesson_videos'),
  lessonAudio('lesson_audio'),
  userUploads('user_uploads'),
  thumbnails('thumbnails');

  const MediaFolder(this.folderName);
  final String folderName;
}

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Initialize storage with proper configuration
  static void _ensureInitialized() {
    // Firebase Storage is automatically initialized with Firebase.initializeApp()
    // No additional setup needed for production
    if (kDebugMode) {
      print('Firebase Storage initialized for bucket: ${_storage.bucket}');
    }
  }
  
  /// Upload image to Firebase Storage with optional Cloudinary sync
  static Future<UploadResult> uploadImage({
    required File imageFile,
    required MediaFolder folder,
    String? customFileName,
    bool syncWithCloudinary = true,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }

      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        throw Exception('Image file is too large (max 50MB)');
      }

      // Generate unique filename with validation
      final originalExtension = path.extension(imageFile.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      
      if (!allowedExtensions.contains(originalExtension)) {
        throw Exception('Unsupported image format. Allowed: ${allowedExtensions.join(', ')}');
      }

      final fileName = customFileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${path.basenameWithoutExtension(imageFile.path)}$originalExtension';
      
      // Create Firebase Storage reference with explicit bucket
      final storageRef = _storage.ref().child('${folder.folderName}/$fileName');
      
      if (kDebugMode) {
        print('Uploading to Firebase Storage: ${folder.folderName}/$fileName');
        print('File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      }
      
      // Start upload task with proper metadata
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: _getContentType(originalExtension),
          cacheControl: 'public, max-age=3600',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'folder': folder.folderName,
            'originalName': path.basename(imageFile.path),
            'fileSize': fileSize.toString(),
          },
        ),
      );
      
      // Monitor progress with better error handling
      late StreamSubscription subscription;
      subscription = uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          if (onProgress != null && snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
          
          if (kDebugMode) {
            print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(1)}%');
          }
        },
        onError: (error) {
          if (kDebugMode) print('Upload progress error: $error');
          subscription.cancel();
        },
      );
      
      // Wait for completion with timeout
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          subscription.cancel();
          throw Exception('Upload timeout - please try again');
        },
      );
      
      subscription.cancel();
      
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
      
      final firebaseUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('Firebase upload successful: $firebaseUrl');
      }
      
      String? cloudinaryUrl;
      
      // Sync with Cloudinary if requested (non-blocking)
      if (syncWithCloudinary) {
        try {
          final cloudinaryResult = await CloudinaryService.uploadImage(
            imageFile: imageFile,
            folder: CloudinaryFolder.values.firstWhere(
              (f) => f.folderName == folder.folderName,
              orElse: () => CloudinaryFolder.userContent,
            ),
            customPublicId: path.basenameWithoutExtension(fileName),
          ).timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              if (kDebugMode) print('Cloudinary upload timeout - continuing with Firebase URL');
              return CloudinaryUploadResult(success: false, error: 'Timeout');
            },
          );
          
          cloudinaryUrl = cloudinaryResult.optimizedUrl;
          
          if (kDebugMode && cloudinaryUrl != null) {
            print('Cloudinary sync successful: $cloudinaryUrl');
          }
        } catch (e) {
          // Cloudinary upload failed, but Firebase succeeded
          if (kDebugMode) print('Cloudinary sync failed: $e');
        }
      }
      
      return UploadResult(
        success: true,
        firebaseUrl: firebaseUrl,
        cloudinaryUrl: cloudinaryUrl,
        fileName: fileName,
        folder: folder.folderName,
      );
      
    } catch (e) {
      if (kDebugMode) print('Firebase Storage upload error: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload image from bytes (for web support)
  static Future<UploadResult> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String fileName,
    required MediaFolder folder,
    bool syncWithCloudinary = true,
    Function(double progress)? onProgress,
  }) async {
    try {
      if (imageBytes.isEmpty) {
        throw Exception('Image data is empty');
      }

      if (imageBytes.length > 50 * 1024 * 1024) { // 50MB limit
        throw Exception('Image file is too large (max 50MB)');
      }

      // Validate file extension
      final extension = path.extension(fileName).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Unsupported image format. Allowed: ${allowedExtensions.join(', ')}');
      }

      // Generate unique filename
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // Create Firebase Storage reference
      final storageRef = _storage.ref().child('${folder.folderName}/$uniqueFileName');
      
      if (kDebugMode) {
        print('Uploading bytes to Firebase Storage: ${folder.folderName}/$uniqueFileName');
        print('Data size: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB');
      }
      
      // Start upload task
      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: _getContentType(extension),
          cacheControl: 'public, max-age=3600',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'folder': folder.folderName,
            'originalName': fileName,
            'fileSize': imageBytes.length.toString(),
            'platform': 'web',
          },
        ),
      );
      
      // Monitor progress
      late StreamSubscription subscription;
      subscription = uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          if (onProgress != null && snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        },
        onError: (error) {
          if (kDebugMode) print('Upload progress error: $error');
          subscription.cancel();
        },
      );
      
      // Wait for completion
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          subscription.cancel();
          throw Exception('Upload timeout - please try again');
        },
      );
      
      subscription.cancel();
      
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
      
      final firebaseUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('Firebase bytes upload successful: $firebaseUrl');
      }
      
      return UploadResult(
        success: true,
        firebaseUrl: firebaseUrl,
        cloudinaryUrl: null, // Cloudinary sync not supported for bytes upload
        fileName: uniqueFileName,
        folder: folder.folderName,
      );
      
    } catch (e) {
      if (kDebugMode) print('Firebase Storage bytes upload error: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Get content type from file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }
  
  /// Upload video to Firebase Storage with optional Cloudinary sync
  static Future<UploadResult> uploadVideo({
    required File videoFile,
    required MediaFolder folder,
    String? customFileName,
    bool syncWithCloudinary = true,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Generate unique filename
      final fileName = customFileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(videoFile.path)}';
      
      // Create Firebase Storage reference
      final storageRef = _storage.ref().child('${folder.folderName}/$fileName');
      
      // Start upload task with metadata
      final uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(
          contentType: 'video/${path.extension(videoFile.path).substring(1)}',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'folder': folder.folderName,
            'type': 'video',
          },
        ),
      );
      
      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });
      
      // Wait for completion
      final snapshot = await uploadTask;
      final firebaseUrl = await snapshot.ref.getDownloadURL();
      
      String? cloudinaryUrl;
      
      // Sync with Cloudinary if requested
      if (syncWithCloudinary) {
        try {
          final cloudinaryResult = await CloudinaryService.uploadVideo(
            videoFile: videoFile,
            folder: CloudinaryFolder.values.firstWhere(
              (f) => f.folderName == folder.folderName,
              orElse: () => CloudinaryFolder.lessonVideos,
            ),
            customPublicId: path.basenameWithoutExtension(fileName),
          );
          cloudinaryUrl = cloudinaryResult.optimizedUrl;
        } catch (e) {
          // Cloudinary upload failed, but Firebase succeeded
          if (kDebugMode) print('Cloudinary sync failed: $e');
        }
      }
      
      return UploadResult(
        success: true,
        firebaseUrl: firebaseUrl,
        cloudinaryUrl: cloudinaryUrl,
        fileName: fileName,
        folder: folder.folderName,
      );
      
    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Upload audio file to Firebase Storage
  static Future<UploadResult> uploadAudio({
    required File audioFile,
    required MediaFolder folder,
    String? customFileName,
    bool syncWithCloudinary = true,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Generate unique filename
      final fileName = customFileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audioFile.path)}';
      
      // Create Firebase Storage reference
      final storageRef = _storage.ref().child('${folder.folderName}/$fileName');
      
      // Start upload task
      final uploadTask = storageRef.putFile(
        audioFile,
        SettableMetadata(
          contentType: 'audio/${path.extension(audioFile.path).substring(1)}',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'folder': folder.folderName,
            'type': 'audio',
          },
        ),
      );
      
      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });
      
      // Wait for completion
      final snapshot = await uploadTask;
      final firebaseUrl = await snapshot.ref.getDownloadURL();
      
      String? cloudinaryUrl;
      
      // Sync with Cloudinary if requested
      if (syncWithCloudinary) {
        try {
          final cloudinaryResult = await CloudinaryService.uploadAudio(
            audioFile: audioFile,
            folder: CloudinaryFolder.values.firstWhere(
              (f) => f.folderName == folder.folderName,
              orElse: () => CloudinaryFolder.lessonAudio,
            ),
            customPublicId: path.basenameWithoutExtension(fileName),
          );
          cloudinaryUrl = cloudinaryResult.optimizedUrl;
        } catch (e) {
          if (kDebugMode) print('Cloudinary sync failed: $e');
        }
      }
      
      return UploadResult(
        success: true,
        firebaseUrl: firebaseUrl,
        cloudinaryUrl: cloudinaryUrl,
        fileName: fileName,
        folder: folder.folderName,
      );
      
    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Delete file from Firebase Storage
  static Future<bool> deleteFile({
    required String filePath,
  }) async {
    try {
      final storageRef = _storage.ref().child(filePath);
      await storageRef.delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Delete failed: $e');
      return false;
    }
  }
  
  /// Get file metadata
  static Future<Map<String, dynamic>?> getFileMetadata({
    required String filePath,
  }) async {
    try {
      final storageRef = _storage.ref().child(filePath);
      final metadata = await storageRef.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated?.toIso8601String(),
        'updated': metadata.updated?.toIso8601String(),
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      if (kDebugMode) print('Get metadata failed: $e');
      return null;
    }
  }
  
  /// Generate thumbnail for video
  static Future<UploadResult?> generateVideoThumbnail({
    required String videoPath,
    required String thumbnailPath,
  }) async {
    try {
      // This would require video_thumbnail package
      // For now, we'll return null and implement later
      return null;
    } catch (e) {
      if (kDebugMode) print('Thumbnail generation failed: $e');
      return null;
    }
  }
  
  /// Compress image before upload
  static Future<File?> compressImage({
    required File imageFile,
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      // This would require flutter_image_compress package
      // For now, return original file
      return imageFile;
    } catch (e) {
      if (kDebugMode) print('Image compression failed: $e');
      return null;
    }
  }
}

class UploadResult {
  final bool success;
  final String? firebaseUrl;
  final String? cloudinaryUrl;
  final String? fileName;
  final String? folder;
  final String? error;
  
  UploadResult({
    required this.success,
    this.firebaseUrl,
    this.cloudinaryUrl,
    this.fileName,
    this.folder,
    this.error,
  });
  
  /// Get the best URL available (prefer Cloudinary for optimization)
  String? get optimizedUrl => cloudinaryUrl ?? firebaseUrl;
  
  /// Get Firebase URL for direct access
  String? get directUrl => firebaseUrl;
  
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'firebaseUrl': firebaseUrl,
      'cloudinaryUrl': cloudinaryUrl,
      'fileName': fileName,
      'folder': folder,
      'error': error,
    };
  }
  
  factory UploadResult.fromMap(Map<String, dynamic> map) {
    return UploadResult(
      success: map['success'] ?? false,
      firebaseUrl: map['firebaseUrl'],
      cloudinaryUrl: map['cloudinaryUrl'],
      fileName: map['fileName'],
      folder: map['folder'],
      error: map['error'],
    );
  }
} 