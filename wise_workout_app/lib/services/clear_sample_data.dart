import 'package:cloud_firestore/cloud_firestore.dart';

class ClearSampleDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Clear all leaderboard data for an event
  static Future<void> clearEventLeaderboard(String eventId) async {
    try {
      print('🗑️ Starting to clear leaderboard data for event: $eventId');
      
      // First check if document exists
      DocumentSnapshot doc = await _firestore
          .collection('eventLeaderboards')
          .doc(eventId)
          .get();
      
      print('📄 Document exists before deletion: ${doc.exists}');
      
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('entries')) {
          List entries = data['entries'] as List;
          print('📊 Found ${entries.length} entries to clear');
        }
      }
      
      // Delete the document
      await _firestore
          .collection('eventLeaderboards')
          .doc(eventId)
          .delete();

      print('✅ Successfully cleared leaderboard data for event $eventId');
      
      // Verify deletion
      DocumentSnapshot verifyDoc = await _firestore
          .collection('eventLeaderboards')
          .doc(eventId)
          .get();
      
      print('📄 Document exists after deletion: ${verifyDoc.exists}');
      
    } catch (e) {
      print('❌ Error clearing leaderboard data: $e');
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // Clear all sample leaderboards (if you want to clear everything)
  static Future<void> clearAllLeaderboards() async {
    try {
      print('🗑️ Clearing all leaderboard data...');
      
      QuerySnapshot querySnapshot = await _firestore
          .collection('eventLeaderboards')
          .get();

      WriteBatch batch = _firestore.batch();
      
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Successfully cleared all leaderboard data');
    } catch (e) {
      print('❌ Error clearing all leaderboard data: $e');
    }
  }
}
