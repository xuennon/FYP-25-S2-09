import 'package:flutter/foundation.dart';
import 'services/firebase_shortlist_service.dart';

class ShortlistEventsState extends ChangeNotifier {
  static final ShortlistEventsState _instance = ShortlistEventsState._internal();
  factory ShortlistEventsState() => _instance;
  ShortlistEventsState._internal() {
    _initializeFromFirebase();
  }

  final Set<String> _shortlistedEventIds = <String>{};
  final FirebaseShortlistService _firebaseService = FirebaseShortlistService();
  bool _isInitialized = false;

  Set<String> get shortlistedEventIds => Set.unmodifiable(_shortlistedEventIds);
  bool get isInitialized => _isInitialized;

  /// Initialize shortlist state from Firebase
  Future<void> _initializeFromFirebase() async {
    try {
      print('📌 Initializing shortlist from Firebase...');
      final firebaseEventIds = await _firebaseService.loadShortlistedEventIds();
      
      _shortlistedEventIds.clear();
      _shortlistedEventIds.addAll(firebaseEventIds);
      _isInitialized = true;
      
      print('📌 Shortlist initialized with ${_shortlistedEventIds.length} events');
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing shortlist from Firebase: $e');
      _isInitialized = true; // Mark as initialized even if failed to prevent infinite loading
      notifyListeners();
    }
  }

  /// Force reload from Firebase
  Future<void> reloadFromFirebase() async {
    await _initializeFromFirebase();
  }

  bool isEventShortlisted(String eventId) {
    return _shortlistedEventIds.contains(eventId);
  }

  /// Add event to shortlist (syncs with Firebase)
  Future<void> shortlistEvent(String eventId) async {
    if (_shortlistedEventIds.add(eventId)) {
      print('📌 Event $eventId added to local shortlist');
      notifyListeners();
      
      // Sync to Firebase
      final success = await _firebaseService.addToShortlist(eventId);
      if (!success) {
        // Rollback local change if Firebase sync failed
        _shortlistedEventIds.remove(eventId);
        notifyListeners();
        print('❌ Failed to sync shortlist addition to Firebase, rolled back');
      }
    }
  }

  /// Remove event from shortlist (syncs with Firebase)
  Future<void> removeFromShortlist(String eventId) async {
    if (_shortlistedEventIds.remove(eventId)) {
      print('📌 Event $eventId removed from local shortlist');
      notifyListeners();
      
      // Sync to Firebase
      final success = await _firebaseService.removeFromShortlist(eventId);
      if (!success) {
        // Rollback local change if Firebase sync failed
        _shortlistedEventIds.add(eventId);
        notifyListeners();
        print('❌ Failed to sync shortlist removal to Firebase, rolled back');
      }
    }
  }

  /// Toggle shortlist status (syncs with Firebase)
  Future<void> toggleShortlist(String eventId) async {
    if (isEventShortlisted(eventId)) {
      await removeFromShortlist(eventId);
    } else {
      await shortlistEvent(eventId);
    }
  }

  List<String> getShortlistedEventIds() {
    return _shortlistedEventIds.toList();
  }

  /// Clear all shortlisted events (syncs with Firebase)
  Future<void> clearShortlist() async {
    final previousIds = Set<String>.from(_shortlistedEventIds);
    _shortlistedEventIds.clear();
    notifyListeners();
    
    // Sync to Firebase
    final success = await _firebaseService.clearShortlist();
    if (!success) {
      // Rollback local change if Firebase sync failed
      _shortlistedEventIds.addAll(previousIds);
      notifyListeners();
      print('❌ Failed to sync shortlist clear to Firebase, rolled back');
    }
  }

  /// Debug method to check Firebase sync
  Future<void> debugFirebaseSync() async {
    await _firebaseService.debugShortlistDocument();
  }
}
