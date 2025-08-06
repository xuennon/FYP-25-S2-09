// Example script for testing suspension functionality
// This shows how to set up test users with different suspension statuses

import 'package:cloud_firestore/cloud_firestore.dart';

class SuspensionTestHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Test method to create a suspended user (for testing purposes)
  static Future<void> createTestSuspendedUser() async {
    try {
      await _firestore.collection('users').doc('test_suspended_user').set({
        'uid': 'test_suspended_user',
        'email': 'suspended@test.com',
        'username': 'SuspendedTestUser',
        'displayName': 'Suspended Test User',
        'gender': 'Male',
        'role': 'user',
        'userType': 'normal',
        'suspensionStatus': 'yes', // This user is suspended
        'suspendedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      print('✅ Test suspended user created');
    } catch (e) {
      print('❌ Error creating test suspended user: $e');
    }
  }

  // Test method to create a normal active user (for testing purposes)
  static Future<void> createTestActiveUser() async {
    try {
      await _firestore.collection('users').doc('test_active_user').set({
        'uid': 'test_active_user',
        'email': 'active@test.com',
        'username': 'ActiveTestUser',
        'displayName': 'Active Test User',
        'gender': 'Female',
        'role': 'user',
        'userType': 'normal',
        'suspensionStatus': 'no', // This user is active
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      print('✅ Test active user created');
    } catch (e) {
      print('❌ Error creating test active user: $e');
    }
  }

  // Test method to create an admin user (for testing purposes)
  static Future<void> createTestAdminUser() async {
    try {
      await _firestore.collection('users').doc('test_admin_user').set({
        'uid': 'test_admin_user',
        'email': 'admin@test.com',
        'username': 'AdminTestUser',
        'displayName': 'Admin Test User',
        'gender': 'Male',
        'role': 'admin', // This user is an admin
        'userType': 'premium',
        'suspensionStatus': 'no',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      print('✅ Test admin user created');
    } catch (e) {
      print('❌ Error creating test admin user: $e');
    }
  }

  // Method to suspend an existing user by email
  static Future<void> suspendUserByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String userId = querySnapshot.docs.first.id;
        await _firestore.collection('users').doc(userId).update({
          'suspensionStatus': 'yes',
          'suspendedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('✅ User $email has been suspended');
      } else {
        print('❌ User with email $email not found');
      }
    } catch (e) {
      print('❌ Error suspending user: $e');
    }
  }

  // Method to unsuspend an existing user by email
  static Future<void> unsuspendUserByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String userId = querySnapshot.docs.first.id;
        await _firestore.collection('users').doc(userId).update({
          'suspensionStatus': 'no',
          'unsuspendedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('✅ User $email has been unsuspended');
      } else {
        print('❌ User with email $email not found');
      }
    } catch (e) {
      print('❌ Error unsuspending user: $e');
    }
  }

  // Method to check a user's suspension status
  static Future<void> checkUserSuspensionStatus(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> userData = 
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        String suspensionStatus = userData['suspensionStatus'] ?? 'no';
        String username = userData['username'] ?? 'Unknown';
        
        print('👤 User: $username ($email)');
        print('📊 Suspension Status: $suspensionStatus');
        print('🔄 Status: ${suspensionStatus == 'yes' ? 'SUSPENDED' : 'ACTIVE'}');
      } else {
        print('❌ User with email $email not found');
      }
    } catch (e) {
      print('❌ Error checking user status: $e');
    }
  }
}

/*
USAGE EXAMPLES:

1. To create test users:
   await SuspensionTestHelper.createTestActiveUser();
   await SuspensionTestHelper.createTestSuspendedUser();
   await SuspensionTestHelper.createTestAdminUser();

2. To suspend a user:
   await SuspensionTestHelper.suspendUserByEmail('user@example.com');

3. To unsuspend a user:
   await SuspensionTestHelper.unsuspendUserByEmail('user@example.com');

4. To check suspension status:
   await SuspensionTestHelper.checkUserSuspensionStatus('user@example.com');

TESTING WORKFLOW:
1. Create a regular user account through the app signup
2. Log in successfully to verify account works
3. Use admin tools to suspend the user
4. Try to log in again - should be blocked with suspension message
5. Use admin tools to unsuspend the user
6. Log in again - should work normally

ADMIN ACCESS:
- Set a user's role to 'admin' in Firestore
- Use AdminHomePage and AdminUserManagementPage to manage suspensions
- Access via direct navigation or create admin login flow
*/
