import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAdminService {
  static final FirebaseAdminService _instance = FirebaseAdminService._internal();
  factory FirebaseAdminService() => _instance;
  FirebaseAdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      if (_auth.currentUser == null) return false;
      
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get all users for admin management
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id; // Add document ID for reference
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Suspend a user
  Future<bool> suspendUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'suspensionStatus': 'yes',
        'suspendedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('User $userId has been suspended');
      return true;
    } catch (e) {
      print('Error suspending user: $e');
      return false;
    }
  }

  // Unsuspend a user
  Future<bool> unsuspendUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'suspensionStatus': 'no',
        'unsuspendedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('User $userId has been unsuspended');
      return true;
    } catch (e) {
      print('Error unsuspending user: $e');
      return false;
    }
  }

  // Get suspended users only
  Future<List<Map<String, dynamic>>> getSuspendedUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('suspensionStatus', isEqualTo: 'yes')
          .orderBy('suspendedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting suspended users: $e');
      return [];
    }
  }

  // Search users by username or email
  Future<List<Map<String, dynamic>>> searchUsers(String searchTerm) async {
    try {
      // Search by username
      QuerySnapshot usernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: searchTerm)
          .where('username', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      // Search by email
      QuerySnapshot emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchTerm)
          .where('email', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      Set<String> addedIds = {};
      List<Map<String, dynamic>> results = [];

      // Add username results
      for (var doc in usernameQuery.docs) {
        if (!addedIds.contains(doc.id)) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          results.add(data);
          addedIds.add(doc.id);
        }
      }

      // Add email results
      for (var doc in emailQuery.docs) {
        if (!addedIds.contains(doc.id)) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          results.add(data);
          addedIds.add(doc.id);
        }
      }

      return results;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get user statistics for admin dashboard
  Future<Map<String, int>> getUserStatistics() async {
    try {
      // Total users
      QuerySnapshot totalUsers = await _firestore.collection('users').get();
      
      // Suspended users
      QuerySnapshot suspendedUsers = await _firestore
          .collection('users')
          .where('suspensionStatus', isEqualTo: 'yes')
          .get();

      // Active users (not suspended)
      QuerySnapshot activeUsers = await _firestore
          .collection('users')
          .where('suspensionStatus', isEqualTo: 'no')
          .get();

      return {
        'total': totalUsers.docs.length,
        'suspended': suspendedUsers.docs.length,
        'active': activeUsers.docs.length,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {
        'total': 0,
        'suspended': 0,
        'active': 0,
      };
    }
  }
}
