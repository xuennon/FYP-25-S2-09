import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_posts_service.dart';
import 'services/firebase_user_profile_service.dart';

// 🧪 TEMPORARY DEBUG WIDGET - Add this to test username sync
// Add this FloatingActionButton to any page to test username sync manually

class UsernameDebugWidget extends StatelessWidget {
  const UsernameDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        await _testUsernameSync(context);
      },
      icon: const Icon(Icons.bug_report),
      label: const Text('Test Sync'),
      backgroundColor: Colors.red,
    );
  }

  static Future<void> _testUsernameSync(BuildContext context) async {
    final FirebasePostsService postsService = FirebasePostsService();
    final FirebaseUserProfileService profileService = FirebaseUserProfileService();
    
    print('🧪 ===== USERNAME SYNC DEBUG TEST =====');
    
    // Check current user
    User? currentUser = FirebaseAuth.instance.currentUser;
    print('🧪 Current user: ${currentUser?.uid}');
    print('🧪 Current email: ${currentUser?.email}');
    
    if (currentUser == null) {
      print('❌ No user logged in!');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ No user logged in!')),
        );
      }
      return;
    }
    
    // Get current username
    try {
      String currentUsername = await profileService.getUsername();
      print('🧪 Current username from profile: $currentUsername');
      
      // Check current posts
      print('🧪 Current posts before sync:');
      for (var post in postsService.posts) {
        print('🧪 Post by ${post.username} (userId: ${post.userId}): ${post.content.substring(0, 20)}...');
      }
      
      // Test sync with a test username
      String testUsername = '${currentUsername}_TEST_${DateTime.now().millisecondsSinceEpoch}';
      print('🧪 Testing sync with username: $testUsername');
      
      bool syncResult = await postsService.syncUsernameAcrossPosts(testUsername);
      print('🧪 Sync result: $syncResult');
      
      // Check posts after sync
      print('🧪 Current posts after sync:');
      for (var post in postsService.posts) {
        print('🧪 Post by ${post.username} (userId: ${post.userId}): ${post.content.substring(0, 20)}...');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(syncResult 
              ? '✅ Sync test completed! Check console logs.' 
              : '❌ Sync test failed! Check console logs.'),
            backgroundColor: syncResult ? Colors.green : Colors.red,
          ),
        );
      }
      
      // Restore original username
      print('🧪 Restoring original username: $currentUsername');
      await postsService.syncUsernameAcrossPosts(currentUsername);
      
    } catch (e) {
      print('❌ Error during sync test: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
    
    print('🧪 ===== USERNAME SYNC DEBUG TEST COMPLETE =====');
  }
}

// 🚀 HOW TO USE THIS DEBUG WIDGET:
/*
1. Add this import to any page where you want to test:
   import 'username_debug_widget.dart';

2. Add this to the Scaffold body or as a floatingActionButton:
   floatingActionButton: const UsernameDebugWidget(),

3. Tap the red "Test Sync" button to run the test

4. Watch the console logs and snackbar messages

5. Remove this widget after testing is complete
*/
