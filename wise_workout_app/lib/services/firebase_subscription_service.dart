import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSubscriptionService {
  static final FirebaseSubscriptionService _instance = FirebaseSubscriptionService._internal();
  factory FirebaseSubscriptionService() => _instance;
  FirebaseSubscriptionService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Update user subscription type
  Future<bool> updateUserSubscription(String userType) async {
    try {
      if (_auth.currentUser == null) {
        print('No authenticated user found');
        return false;
      }

      String uid = _auth.currentUser!.uid;
      
      await _firestore.collection('users').doc(uid).update({
        'userType': userType,
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('User subscription updated to: $userType for user: $uid');
      return true;
    } catch (e) {
      print('Error updating user subscription: $e');
      return false;
    }
  }

  // Get user subscription type
  Future<String> getUserSubscriptionType() async {
    try {
      if (_auth.currentUser == null) {
        print('No authenticated user found');
        return 'normal'; // Default to normal if no user
      }

      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['userType'] ?? 'normal'; // Default to normal if field doesn't exist
      } else {
        print('User document does not exist');
        return 'normal';
      }
    } catch (e) {
      print('Error fetching user subscription type: $e');
      return 'normal';
    }
  }

  // Check if user has premium subscription
  Future<bool> hasPremiumSubscription() async {
    String userType = await getUserSubscriptionType();
    return userType == 'premium';
  }

  // Activate free subscription
  Future<bool> activateFreeSubscription() async {
    return await updateUserSubscription('normal');
  }

  // Activate premium subscription
  Future<bool> activatePremiumSubscription() async {
    return await updateUserSubscription('premium');
  }

  // Get subscription details
  Future<Map<String, dynamic>> getSubscriptionDetails() async {
    try {
      if (_auth.currentUser == null) {
        return {
          'userType': 'normal',
          'subscriptionUpdatedAt': null,
          'isActive': false,
        };
      }

      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return {
          'userType': userData['userType'] ?? 'normal',
          'subscriptionUpdatedAt': userData['subscriptionUpdatedAt'],
          'isActive': userData['userType'] != null,
        };
      } else {
        return {
          'userType': 'normal',
          'subscriptionUpdatedAt': null,
          'isActive': false,
        };
      }
    } catch (e) {
      print('Error fetching subscription details: $e');
      return {
        'userType': 'normal',
        'subscriptionUpdatedAt': null,
        'isActive': false,
      };
    }
  }
}
