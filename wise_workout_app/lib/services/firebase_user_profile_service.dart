import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        'gender': 'Man',
        'role': 'user',
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

      // Add non-null values to update data
      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
        updateData['displayName'] = username;
        // Also update Firebase Auth display name
        await _auth.currentUser!.updateDisplayName(username);
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
      String gender = profile?['gender'] ?? 'Man';
      
      // Ensure the gender is one of the valid options
      List<String> validGenders = ['Man', 'Woman', 'Other', 'Prefer not to say'];
      
      return validGenders.contains(gender) ? gender : 'Man';
    } catch (e) {
      print('Error getting gender: $e');
      return 'Man';
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
}
