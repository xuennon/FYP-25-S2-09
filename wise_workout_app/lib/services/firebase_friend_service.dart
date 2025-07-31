import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFriendService {
  static final FirebaseFriendService _instance = FirebaseFriendService._internal();
  factory FirebaseFriendService() => _instance;
  FirebaseFriendService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Search users by username
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.isEmpty || currentUserId == null) return [];

      print('🔍 Searching for users with query: "$query"');
      print('🔑 Current user ID: $currentUserId');

      // Search for users whose username contains the query (case-insensitive)
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      print('📊 Found ${querySnapshot.docs.length} documents');

      List<Map<String, dynamic>> users = [];
      
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        String documentId = doc.id;  // Get the document ID directly
        Map<String, dynamic> originalData = doc.data() as Map<String, dynamic>;
        
        print('📄 Document ID: $documentId');
        print('👤 Username: ${originalData['username']}');
        
        // Create a completely new map with the document ID
        Map<String, dynamic> userWithId = {
          'documentId': documentId,
          'userId': documentId,
          'uid': documentId,
        };
        
        // Add all original data to the new map
        originalData.forEach((key, value) {
          userWithId[key] = value;
        });
        
        print('✅ Final user data: $userWithId');
        print('� Keys available: ${userWithId.keys.toList()}');
        
        // Don't include current user in search results
        if (documentId != currentUserId) {
          users.add(userWithId);
          print('➕ Added user: ${userWithId['username']} (ID: $documentId)');
        } else {
          print('⏭️ Skipped current user: ${userWithId['username']}');
        }
      }

      print('🎯 Total users to return: ${users.length}');
      return users;
    } catch (e) {
      print('❌ Error searching users: $e');
      print('📋 Error details: ${e.toString()}');
      return [];
    }
  }

  // Follow a user
  Future<bool> followUser(String targetUserId, String targetUsername) async {
    try {
      if (currentUserId == null) {
        print('Error: User not authenticated');
        return false;
      }

      if (targetUserId.isEmpty) {
        print('Error: Target user ID is empty');
        return false;
      }

      print('Attempting to follow user: $targetUsername (ID: $targetUserId)');
      print('Current user ID: $currentUserId');

      // Check if target user exists
      DocumentSnapshot targetUserDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();
      
      if (!targetUserDoc.exists) {
        print('Error: Target user does not exist in database');
        return false;
      }

      // Add to current user's following list (only store userId and timestamp)
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .set({
        'userId': targetUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });

      print('Added to following list successfully');

      // Add current user to target user's followers list (only store userId and timestamp)
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .set({
        'userId': currentUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });

      print('Added to followers list successfully');
      print('Successfully followed user: $targetUsername');
      return true;
    } catch (e) {
      print('Error following user: $e');
      print('Error details: ${e.toString()}');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      if (currentUserId == null) return false;

      // Remove from current user's following list
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .delete();

      // Remove current user from target user's followers list
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .delete();

      print('Successfully unfollowed user: $targetUserId');
      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Check if current user is following a specific user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      if (currentUserId == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Get list of users current user is following
  Future<List<Map<String, dynamic>>> getFollowing() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .orderBy('followedAt', descending: true)
          .get();

      List<Map<String, dynamic>> following = [];
      
      // For each followed user, get their current user data
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> followData = doc.data() as Map<String, dynamic>;
        String followedUserId = followData['userId'];
        
        // Fetch the current user data to get updated username
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(followedUserId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          // Combine follow data with current user data
          Map<String, dynamic> combinedData = {
            'userId': followedUserId,
            'username': userData['username'] ?? 'Unknown User',
            'email': userData['email'] ?? '',
            'followedAt': followData['followedAt'],
          };
          following.add(combinedData);
        }
      }

      print('Found ${following.length} users being followed');
      return following;
    } catch (e) {
      print('Error getting following list: $e');
      return [];
    }
  }

  // Get list of followers
  Future<List<Map<String, dynamic>>> getFollowers() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followers')
          .orderBy('followedAt', descending: true)
          .get();

      List<Map<String, dynamic>> followers = [];
      
      // For each follower, get their current user data
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> followerData = doc.data() as Map<String, dynamic>;
        String followerUserId = followerData['userId'];
        
        // Fetch the current user data to get updated username
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(followerUserId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          // Combine follower data with current user data
          Map<String, dynamic> combinedData = {
            'userId': followerUserId,
            'username': userData['username'] ?? 'Unknown User',
            'email': userData['email'] ?? '',
            'followedAt': followerData['followedAt'],
          };
          followers.add(combinedData);
        }
      }

      print('Found ${followers.length} followers');
      return followers;
    } catch (e) {
      print('Error getting followers list: $e');
      return [];
    }
  }

  // Get follow counts (following and followers count)
  Future<Map<String, int>> getFollowCounts() async {
    try {
      if (currentUserId == null) return {'following': 0, 'followers': 0};

      // Get following count
      QuerySnapshot followingSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .get();

      // Get followers count
      QuerySnapshot followersSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followers')
          .get();

      return {
        'following': followingSnapshot.docs.length,
        'followers': followersSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting follow counts: $e');
      return {'following': 0, 'followers': 0};
    }
  }

  // Get current user information by user ID
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      if (userId.isEmpty) return null;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['userId'] = userId; // Add the user ID to the data
        return userData;
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}
