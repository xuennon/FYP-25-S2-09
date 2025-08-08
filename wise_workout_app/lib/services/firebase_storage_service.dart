import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload a single image file to Firebase Storage
  /// Returns the download URL if successful, null if failed
  Future<String?> uploadImage(File imageFile, {String? customPath}) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ Firebase Storage: User not authenticated');
        return null;
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'img_${timestamp}_${imageFile.path.split('/').last}';
      
      // Create reference with custom path or default path
      final String uploadPath = customPath ?? 'posts/$userId/$fileName';
      final Reference ref = _storage.ref().child(uploadPath);

      print('📤 Firebase Storage: Uploading image to $uploadPath');

      // Upload file
      final UploadTask uploadTask = ref.putFile(imageFile);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Firebase Storage: Image uploaded successfully');
      print('🔗 Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ Firebase Storage: Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple image files to Firebase Storage
  /// Returns a list of download URLs for successful uploads
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    List<String> downloadUrls = [];
    
    print('📤 Firebase Storage: Uploading ${imageFiles.length} images...');
    
    for (int i = 0; i < imageFiles.length; i++) {
      File imageFile = imageFiles[i];
      print('📤 Uploading image ${i + 1}/${imageFiles.length}...');
      
      String? downloadUrl = await uploadImage(imageFile);
      if (downloadUrl != null) {
        downloadUrls.add(downloadUrl);
        print('✅ Image ${i + 1} uploaded successfully');
      } else {
        print('❌ Failed to upload image ${i + 1}');
      }
    }
    
    print('✅ Firebase Storage: ${downloadUrls.length}/${imageFiles.length} images uploaded successfully');
    return downloadUrls;
  }

  /// Delete an image from Firebase Storage using its download URL
  Future<bool> deleteImageByUrl(String downloadUrl) async {
    try {
      // Extract the path from the download URL
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      
      print('✅ Firebase Storage: Image deleted successfully');
      return true;
    } catch (e) {
      print('❌ Firebase Storage: Error deleting image: $e');
      return false;
    }
  }

  /// Delete multiple images from Firebase Storage
  Future<void> deleteImages(List<String> downloadUrls) async {
    print('🗑️ Firebase Storage: Deleting ${downloadUrls.length} images...');
    
    for (String url in downloadUrls) {
      await deleteImageByUrl(url);
    }
  }

  /// Get the size of an image in Firebase Storage
  Future<int?> getImageSize(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      final FullMetadata metadata = await ref.getMetadata();
      return metadata.size;
    } catch (e) {
      print('❌ Firebase Storage: Error getting image size: $e');
      return null;
    }
  }

  /// Check if an image exists in Firebase Storage
  Future<bool> imageExists(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }
}
