import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseStorageTest {
  static Future<void> testConnection() async {
    try {
      print('🔄 Testing Firebase Storage connection...');
      
      // Check authentication
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      print('✅ User authenticated: ${user.uid}');
      
      // Test Firebase Storage access
      final FirebaseStorage storage = FirebaseStorage.instance;
      final Reference testRef = storage.ref().child('test/connection_test.txt');
      
      print('🔄 Testing Firebase Storage write access...');
      
      // Try to upload a simple text file
      const String testContent = 'Firebase Storage connection test';
      final UploadTask uploadTask = testRef.putString(testContent);
      
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print('✅ Firebase Storage write test successful!');
        print('🔗 Test file URL: $downloadUrl');
        
        // Clean up test file
        await testRef.delete();
        print('🗑️ Test file cleaned up');
      } else {
        print('❌ Firebase Storage write test failed: ${snapshot.state}');
      }
      
    } catch (e) {
      print('❌ Firebase Storage test error: $e');
      
      // Check specific error types
      if (e.toString().contains('permission-denied')) {
        print('💡 Suggestion: Check Firebase Storage security rules');
      } else if (e.toString().contains('network')) {
        print('💡 Suggestion: Check internet connection');
      } else if (e.toString().contains('unauthenticated')) {
        print('💡 Suggestion: Make sure user is properly signed in');
      }
    }
  }
}
