import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseShortlistService {
  static final FirebaseShortlistService _instance = FirebaseShortlistService._internal();
  factory FirebaseShortlistService() => _instance;
  FirebaseShortlistService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get the user's shortlist document reference
  DocumentReference? get _userShortlistDoc {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('shortlist').doc(userId);
  }

  /// Load shortlisted event IDs from Firebase
  Future<Set<String>> loadShortlistedEventIds() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('⚠️ No authenticated user for shortlist');
        return <String>{};
      }

      final docSnapshot = await _userShortlistDoc!.get();
      
      if (!docSnapshot.exists) {
        print('📌 No shortlist document found for user $userId');
        return <String>{};
      }

      final data = docSnapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        print('📌 Shortlist document exists but has no data');
        return <String>{};
      }

      // Get the eventIds array from the document
      final List<dynamic> eventIdsList = data['eventIds'] ?? [];
      final Set<String> eventIds = eventIdsList.cast<String>().toSet();
      
      print('📌 Loaded ${eventIds.length} shortlisted events from Firebase');
      print('📌 Event IDs: $eventIds');
      
      return eventIds;
    } catch (e) {
      print('❌ Error loading shortlisted events: $e');
      return <String>{};
    }
  }

  /// Add an event to the user's shortlist in Firebase
  Future<bool> addToShortlist(String eventId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('⚠️ No authenticated user for adding to shortlist');
        return false;
      }

      await _userShortlistDoc!.set({
        'eventIds': FieldValue.arrayUnion([eventId]),
        'userId': userId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Added event $eventId to shortlist in Firebase');
      return true;
    } catch (e) {
      print('❌ Error adding event to shortlist: $e');
      return false;
    }
  }

  /// Remove an event from the user's shortlist in Firebase
  Future<bool> removeFromShortlist(String eventId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('⚠️ No authenticated user for removing from shortlist');
        return false;
      }

      await _userShortlistDoc!.update({
        'eventIds': FieldValue.arrayRemove([eventId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Removed event $eventId from shortlist in Firebase');
      return true;
    } catch (e) {
      print('❌ Error removing event from shortlist: $e');
      return false;
    }
  }

  /// Sync local shortlist state to Firebase
  Future<bool> syncShortlistToFirebase(Set<String> localEventIds) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('⚠️ No authenticated user for syncing shortlist');
        return false;
      }

      await _userShortlistDoc!.set({
        'eventIds': localEventIds.toList(),
        'userId': userId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Synced ${localEventIds.length} shortlisted events to Firebase');
      return true;
    } catch (e) {
      print('❌ Error syncing shortlist to Firebase: $e');
      return false;
    }
  }

  /// Get a stream of shortlisted event IDs for real-time updates
  Stream<Set<String>> getShortlistStream() {
    final userId = currentUserId;
    if (userId == null) {
      print('⚠️ No authenticated user for shortlist stream');
      return Stream.value(<String>{});
    }

    return _userShortlistDoc!.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return <String>{};
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        return <String>{};
      }

      final List<dynamic> eventIdsList = data['eventIds'] ?? [];
      return eventIdsList.cast<String>().toSet();
    }).handleError((error) {
      print('❌ Error in shortlist stream: $error');
      return <String>{};
    });
  }

  /// Clear all shortlisted events for the current user
  Future<bool> clearShortlist() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('⚠️ No authenticated user for clearing shortlist');
        return false;
      }

      await _userShortlistDoc!.set({
        'eventIds': [],
        'userId': userId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Cleared shortlist in Firebase');
      return true;
    } catch (e) {
      print('❌ Error clearing shortlist: $e');
      return false;
    }
  }

  /// Debug: Check if shortlist document exists and print its contents
  Future<void> debugShortlistDocument() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('🐛 DEBUG: No authenticated user');
        return;
      }

      print('🐛 DEBUG: Checking shortlist document for user $userId');
      
      final docSnapshot = await _userShortlistDoc!.get();
      
      if (!docSnapshot.exists) {
        print('🐛 DEBUG: Document does not exist');
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>?;
      print('🐛 DEBUG: Document data: $data');
      
      if (data != null) {
        final eventIds = data['eventIds'] ?? [];
        print('🐛 DEBUG: Event IDs in Firebase: $eventIds');
      }
    } catch (e) {
      print('🐛 DEBUG ERROR: $e');
    }
  }
}
