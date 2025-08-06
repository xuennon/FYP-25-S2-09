import 'package:cloud_firestore/cloud_firestore.dart';

// One-time script to clear all sample leaderboard data
// Run this in your main.dart temporarily or call it from anywhere in your app

class DataCleanup {
  static Future<void> clearAllLeaderboardData() async {
    try {
      print('🗑️ Starting cleanup of all leaderboard data...');
      
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Get all documents in eventLeaderboards collection
      QuerySnapshot eventLeaderboardsSnapshot = await firestore
          .collection('eventLeaderboards')
          .get();
      
      print('📊 Found ${eventLeaderboardsSnapshot.docs.length} leaderboard documents');
      
      // Delete each document
      WriteBatch batch = firestore.batch();
      for (QueryDocumentSnapshot doc in eventLeaderboardsSnapshot.docs) {
        print('🗑️ Deleting leaderboard: ${doc.id}');
        batch.delete(doc.reference);
      }
      
      // Also clear old 'leaderboards' collection if it exists
      QuerySnapshot oldLeaderboardsSnapshot = await firestore
          .collection('leaderboards')
          .get();
          
      print('📊 Found ${oldLeaderboardsSnapshot.docs.length} old leaderboard documents');
      
      for (QueryDocumentSnapshot doc in oldLeaderboardsSnapshot.docs) {
        print('🗑️ Deleting old leaderboard: ${doc.id}');
        batch.delete(doc.reference);
      }
      
      // Commit all deletions
      await batch.commit();
      
      print('✅ Successfully cleared all leaderboard data!');
      print('🎯 Leaderboards will now show empty state until real activities are recorded');
      
    } catch (e) {
      print('❌ Error clearing leaderboard data: $e');
    }
  }
}
