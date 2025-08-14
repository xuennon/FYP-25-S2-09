import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_posts_service.dart';

class FirebaseUserProfileService {
  static final FirebaseUserProfileService _instance = FirebaseUserProfileService._internal();
  factory FirebaseUserProfileService() => _instance;
  FirebaseUserProfileService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (_auth.currentUser == null) {
        print('No authenticated user found');
        return null;
      }

      String uid = _auth.currentUser!.uid;
      print('Fetching profile for user: $uid');

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('User profile data retrieved: $userData');
        return userData;
      } else {
        print('User document does not exist in Firestore');
        // Create a basic user document if it doesn't exist
        await _createBasicUserProfile();
        return await getUserProfile(); // Retry after creating
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Create basic user profile if it doesn't exist
  Future<void> _createBasicUserProfile() async {
    try {
      if (_auth.currentUser == null) return;

      String uid = _auth.currentUser!.uid;
      String email = _auth.currentUser!.email ?? '';
      String displayName = _auth.currentUser!.displayName ?? 'User';

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': displayName,
        'displayName': displayName,
        'gender': 'Male',
        'role': 'user',
        'userType': 'normal', // Default to normal (free) subscription
        'suspensionStatus': 'no', // Default to not suspended
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use merge to avoid overwriting existing data

      print('Basic user profile created for: $uid');
    } catch (e) {
      print('Error creating basic user profile: $e');
    }
  }

  // Update user profile data in Firestore
  Future<bool> updateUserProfile({
    String? username,
    String? gender,
    String? height,
    String? weight,
    String? bmi,
  }) async {
    try {
      if (_auth.currentUser == null) {
        print('No authenticated user found');
        return false;
      }

      String uid = _auth.currentUser!.uid;
      Map<String, dynamic> updateData = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Track if username is being updated
      bool usernameUpdated = false;
      String? newUsername;

      // Add non-null values to update data
      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
        updateData['displayName'] = username;
        // Also update Firebase Auth display name
        await _auth.currentUser!.updateDisplayName(username);
        usernameUpdated = true;
        newUsername = username;
      }

      if (gender != null && gender.isNotEmpty) {
        updateData['gender'] = gender;
      }

      if (height != null && height.isNotEmpty) {
        updateData['height'] = height;
      }

      if (weight != null && weight.isNotEmpty) {
        updateData['weight'] = weight;
      }

      if (bmi != null && bmi.isNotEmpty) {
        updateData['bmi'] = bmi;
      }

      await _firestore.collection('users').doc(uid).update(updateData);
      print('User profile updated successfully: $updateData');

      // 🔥 NEW: Sync username across all posts if username was updated
      if (usernameUpdated && newUsername != null) {
        print('🔄 Syncing username across posts...');
        final FirebasePostsService postsService = FirebasePostsService();
        bool syncSuccess = await postsService.syncUsernameAcrossPosts(newUsername);
        if (syncSuccess) {
          print('✅ Username synced across all posts successfully');
        } else {
          print('⚠️ Username sync across posts failed, but profile was updated');
        }
      }

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Get username for current user
  Future<String> getUsername() async {
    try {
      Map<String, dynamic>? profile = await getUserProfile();
      return profile?['username'] ?? profile?['displayName'] ?? 'User';
    } catch (e) {
      print('Error getting username: $e');
      return 'User';
    }
  }

  // Get gender for current user
  Future<String> getGender() async {
    try {
      Map<String, dynamic>? profile = await getUserProfile();
      String gender = profile?['gender'] ?? 'Male';
      
      // Handle backward compatibility - convert old values to new ones
      if (gender == 'Man') {
        gender = 'Male';
      } else if (gender == 'Woman') {
        gender = 'Female';
      }
      
      // Ensure the gender is one of the valid options
      List<String> validGenders = ['Male', 'Female', 'Other', 'Prefer not to say'];
      
      return validGenders.contains(gender) ? gender : 'Male';
    } catch (e) {
      print('Error getting gender: $e');
      return 'Male';
    }
  }

  // Get health information for current user
  Future<Map<String, String>> getHealthInfo() async {
    try {
      Map<String, dynamic>? profile = await getUserProfile();
      return {
        'height': profile?['height'] ?? '',
        'weight': profile?['weight'] ?? '',
        'bmi': profile?['bmi'] ?? '',
      };
    } catch (e) {
      print('Error getting health info: $e');
      return {'height': '', 'weight': '', 'bmi': ''};
    }
  }

  // Check if user profile exists
  Future<bool> profileExists() async {
    try {
      if (_auth.currentUser == null) return false;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      return userDoc.exists;
    } catch (e) {
      print('Error checking if profile exists: $e');
      return false;
    }
  }

  // Manual username sync across posts (useful for fixing data inconsistencies)
  Future<bool> syncUsernameAcrossPosts() async {
    try {
      String currentUsername = await getUsername();
      final FirebasePostsService postsService = FirebasePostsService();
      return await postsService.syncUsernameAcrossPosts(currentUsername);
    } catch (e) {
      print('Error manually syncing username across posts: $e');
      return false;
    }
  }

  // Get user subscription type
  Future<String> getUserType() async {
    try {
      Map<String, dynamic>? profile = await getUserProfile();
      return profile?['userType'] ?? 'normal';
    } catch (e) {
      print('Error getting user type: $e');
      return 'normal';
    }
  }

  // Check if user has premium subscription
  Future<bool> hasPremiumSubscription() async {
    String userType = await getUserType();
    return userType == 'premium';
  }

  // Get user suspension status
  Future<String> getSuspensionStatus() async {
    try {
      Map<String, dynamic>? profile = await getUserProfile();
      return profile?['suspensionStatus'] ?? 'no';
    } catch (e) {
      print('Error getting suspension status: $e');
      return 'no'; // Default to not suspended if error occurs
    }
  }

  // Check if user is suspended
  Future<bool> isUserSuspended() async {
    String suspensionStatus = await getSuspensionStatus();
    return suspensionStatus == 'yes';
  }

  // Get user profile by user ID
  Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    try {
      print('Fetching profile for user ID: $userId');

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('User profile data retrieved for $userId: ${userData['username'] ?? 'No username'}');
        return userData;
      } else {
        print('User document does not exist in Firestore for ID: $userId');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile for ID $userId: $e');
      return null;
    }
  }
}
