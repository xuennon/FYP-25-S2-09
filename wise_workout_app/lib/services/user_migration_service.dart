import 'package:cloud_firestore/cloud_firestore.dart';

// This is a utility script to migrate existing users to have the userType field
// You can call this once to update all existing users in your database
class UserMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate all existing users to have userType field
  static Future<void> migrateExistingUsers() async {
    try {
      print('Starting user migration...');
      
      // Get all users from the users collection
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int updatedUsers = 0;
      int skippedUsers = 0;
      
      print('Found $totalUsers users to migrate');
      
      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        try {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          // Check if user already has userType field
          if (userData.containsKey('userType')) {
            print('User ${userDoc.id} already has userType: ${userData['userType']}');
            skippedUsers++;
            continue;
          }
          
          // Add userType field with default value 'normal'
          await _firestore.collection('users').doc(userDoc.id).update({
            'userType': 'normal',
            'migrationUpdatedAt': FieldValue.serverTimestamp(),
          });
          
          updatedUsers++;
          print('Updated user ${userDoc.id} with userType: normal');
          
        } catch (e) {
          print('Error updating user ${userDoc.id}: $e');
        }
      }
      
      print('Migration completed!');
      print('Total users: $totalUsers');
      print('Updated users: $updatedUsers');
      print('Skipped users: $skippedUsers');
      
    } catch (e) {
      print('Error during migration: $e');
    }
  }

  // Check migration status
  static Future<Map<String, int>> checkMigrationStatus() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int usersWithUserType = 0;
      int normalUsers = 0;
      int premiumUsers = 0;
      
      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        if (userData.containsKey('userType')) {
          usersWithUserType++;
          String userType = userData['userType'] ?? 'normal';
          if (userType == 'premium') {
            premiumUsers++;
          } else {
            normalUsers++;
          }
        }
      }
      
      return {
        'total': totalUsers,
        'withUserType': usersWithUserType,
        'normal': normalUsers,
        'premium': premiumUsers,
        'needsMigration': totalUsers - usersWithUserType,
      };
      
    } catch (e) {
      print('Error checking migration status: $e');
      return {
        'total': 0,
        'withUserType': 0,
        'normal': 0,
        'premium': 0,
        'needsMigration': 0,
      };
    }
  }

  // Print current database status
  static Future<void> printDatabaseStatus() async {
    Map<String, int> status = await checkMigrationStatus();
    
    print('=== Database Status ===');
    print('Total users: ${status['total']}');
    print('Users with userType: ${status['withUserType']}');
    print('Normal users: ${status['normal']}');
    print('Premium users: ${status['premium']}');
    print('Users needing migration: ${status['needsMigration']}');
    print('=======================');
  }
}
