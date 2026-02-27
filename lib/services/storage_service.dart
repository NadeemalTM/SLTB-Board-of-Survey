import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for uploading photos to Firebase Storage
/// Photos are stored under: survey_photos/{year}/{assetCode}/photo_1.jpg
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a single photo to Firebase Storage
  /// Returns the download URL on success, null on failure
  Future<String?> uploadPhoto({
    required String assetCode,
    required String localPath,
    required int photoNumber,
  }) async {
    try {
      if (kIsWeb) return null; // Skip on web

      final file = File(localPath);
      if (!await file.exists()) {
        print('[Storage] File not found: $localPath');
        return null;
      }

      final year = DateTime.now().year.toString();
      final storagePath =
          'survey_photos/$year/$assetCode/photo_$photoNumber.jpg';

      final ref = _storage.ref().child(storagePath);

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'assetCode': assetCode,
          'photoNumber': photoNumber.toString(),
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('[Storage] Uploaded photo $photoNumber for $assetCode');
      return downloadUrl;
    } catch (e) {
      print('[Storage] Upload failed for photo $photoNumber: $e');
      return null;
    }
  }

  /// Upload all available photos for an asset (up to 3)
  /// Returns a list of download URLs (may contain nulls for failed uploads)
  Future<List<String?>> uploadAllPhotos({
    required String assetCode,
    String? image1Path,
    String? image2Path,
    String? image3Path,
  }) async {
    final paths = [image1Path, image2Path, image3Path];
    final urls = <String?>[null, null, null];

    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (path != null && path.isNotEmpty) {
        // Skip if already a URL (already uploaded)
        if (path.startsWith('http://') || path.startsWith('https://')) {
          urls[i] = path;
          continue;
        }

        urls[i] = await uploadPhoto(
          assetCode: assetCode,
          localPath: path,
          photoNumber: i + 1,
        );
      }
    }

    return urls;
  }

  /// Delete all photos for an asset
  Future<void> deletePhotos(String assetCode) async {
    try {
      final year = DateTime.now().year.toString();
      final ref = _storage.ref().child('survey_photos/$year/$assetCode');
      final list = await ref.listAll();
      for (final item in list.items) {
        await item.delete();
      }
    } catch (e) {
      print('[Storage] Delete failed: $e');
    }
  }
}
