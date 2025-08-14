import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/event.dart';

class FirebaseEventsService extends ChangeNotifier {
  static final FirebaseEventsService _instance = FirebaseEventsService._internal();
  factory FirebaseEventsService() => _instance;
  FirebaseEventsService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Event> _allEvents = [];
  List<Event> _activeEvents = [];
  List<Event> _availableEvents = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _eventsSubscription;

  List<Event> get allEvents => List.unmodifiable(_allEvents);
  List<Event> get activeEvents => List.unmodifiable(_activeEvents);
  List<Event> get availableEvents => List.unmodifiable(_availableEvents);
  bool get isLoading => _isLoading;
  String? get currentUserId => _auth.currentUser?.uid;

  // Load all events from Firebase
  Future<void> loadEvents() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Loading events from Firebase...');

      // Query all events from the 'events' collection
      print('🔍 Querying events collection...');
      QuerySnapshot eventsSnapshot = await _firestore
          .collection('events')
          .get();

      print('📄 Found ${eventsSnapshot.docs.length} documents in events collection');

      // If no events found, log for debugging
      if (eventsSnapshot.docs.isEmpty) {
        print('⚠️ No events found in the events collection');
        print('� Current user ID: ${_auth.currentUser?.uid}');
        print('🔑 User authenticated: ${_auth.currentUser != null}');
      }

      List<Event> loadedEvents = [];

      for (QueryDocumentSnapshot doc in eventsSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Debug: Print the raw data from Firebase
          print('📄 Raw event data from Firebase:');
          print('Document ID: ${doc.id}');
          print('Data: $data');
          
          // Skip team events in the general events list
          // Team events are identified by having 'isTeamEvent' = true or 'teamId' field
          bool isTeamEvent = data['isTeamEvent'] == true || data['teamId'] != null;
          if (isTeamEvent) {
            print('🏃‍♂️ Skipping team event: ${data['name']} (will be loaded separately for teams)');
            continue;
          }
          
          // Use the Event.fromMap factory constructor with better error handling
          Event event = Event.fromMap(doc.id, data);
          
          // Check if current user has joined this event
          if (currentUserId != null && event.participants.contains(currentUserId)) {
            event.isActive = true;
          }
          
          loadedEvents.add(event);
          
          print('✅ Successfully converted event: ${event.name}');
        } catch (e) {
          print('❌ Error converting event ${doc.id}: $e');
          print('❌ Error details: ${e.toString()}');
          // Continue with other events even if one fails
        }
      }

      _allEvents = loadedEvents;
      _categorizeEvents();

      print('✅ Loaded ${_allEvents.length} events successfully');
      print('📊 Active: ${_activeEvents.length}, Available: ${_availableEvents.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading events: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert Firebase data to Event object
  Future<Event> _convertFirebaseDataToEvent(String docId, Map<String, dynamic> data) async {
    try {
      // Check if current user has joined this event
      bool isJoined = false;
      if (currentUserId != null) {
        List<dynamic> participants = data['participants'] ?? [];
        isJoined = participants.contains(currentUserId);
      }

      // Handle both business user format and mobile app format
      DateTime startDate;
      DateTime endDate;
      
      // Convert dates from different formats
      if (data['start'] != null) {
        // Business user format (String)
        if (data['start'] is String) {
          startDate = DateTime.parse(data['start']);
        } else {
          startDate = (data['start'] as Timestamp).toDate();
        }
      } else if (data['startDate'] != null) {
        // Mobile app format (Timestamp or String)
        if (data['startDate'] is String) {
          startDate = DateTime.parse(data['startDate']);
        } else {
          startDate = (data['startDate'] as Timestamp).toDate();
        }
      } else {
        startDate = DateTime.now();
      }
      
      if (data['end'] != null) {
        // Business user format (String)
        if (data['end'] is String) {
          endDate = DateTime.parse(data['end']);
        } else {
          endDate = (data['end'] as Timestamp).toDate();
        }
      } else if (data['endDate'] != null) {
        // Mobile app format (Timestamp or String)
        if (data['endDate'] is String) {
          endDate = DateTime.parse(data['endDate']);
        } else {
          endDate = (data['endDate'] as Timestamp).toDate();
        }
      } else {
        endDate = startDate.add(const Duration(hours: 2)); // Default 2 hours
      }

      // Extract basic fields
      String eventName = data['name'] ?? 'Unnamed Event';
      String businessId = data['businessId'] ?? data['uid'] ?? data['createdBy'] ?? '';
      String businessName = data['businessName'] ?? 'Unknown Business';
      String description = data['description'] ?? '';
      String createdBy = data['createdBy'] ?? businessId;
      
      // Handle sports array (new format) or fallback to sportType (old format)
      List<String> sports = [];
      if (data['sports'] != null && data['sports'] is List) {
        sports = List<String>.from(data['sports']);
      } else if (data['sportType'] != null) {
        // Convert old sportType to sports array
        sports = [data['sportType'].toString().toLowerCase()];
      } else {
        // Infer from name if no sport data available
        sports = [_inferSportTypeFromName(eventName).toLowerCase()];
      }
      
      // Handle participants
      List<String> participants = [];
      if (data['participants'] != null) {
        participants = List<String>.from(data['participants']);
      }
      
      // Handle other optional fields
      int? maxParticipants = data['maxParticipants'];
      
      // Handle metrics
      Map<String, dynamic>? metrics;
      if (data['metrics'] != null) {
        metrics = Map<String, dynamic>.from(data['metrics']);
      }
      
      // Handle createdAt
      DateTime createdAt;
      if (data['createdAt'] != null) {
        if (data['createdAt'] is String) {
          createdAt = DateTime.parse(data['createdAt']);
        } else {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }
      } else {
        createdAt = DateTime.now(); // Default for business events without createdAt
      }

      print('🎯 Converting event: $eventName (Sports: ${sports.join(', ')}) by $businessName');
      print('📅 Event dates: ${startDate.toString()} to ${endDate.toString()}');

      return Event(
        id: docId,
        name: eventName,
        description: description,
        businessId: businessId,
        businessName: businessName,
        createdBy: createdBy,
        sports: sports,
        startDate: startDate,
        endDate: endDate,
        participants: participants,
        maxParticipants: maxParticipants,
        isActive: isJoined,
        createdAt: createdAt,
        metrics: metrics,
      );
      
    } catch (e) {
      print('❌ Error converting event $docId: $e');
      print('📊 Raw event data: $data');
      rethrow;
    }
  }

  // Helper method to infer sport type from event name
  String _inferSportTypeFromName(String name) {
    String lowerName = name.toLowerCase();
    
    if (lowerName.contains('run') || lowerName.contains('jog') || lowerName.contains('sprint')) {
      return 'Run';
    } else if (lowerName.contains('bike') || lowerName.contains('cycle') || lowerName.contains('ride')) {
      return 'Ride';
    } else if (lowerName.contains('swim') || lowerName.contains('pool') || lowerName.contains('water')) {
      return 'Swim';
    } else if (lowerName.contains('walk') || lowerName.contains('stroll')) {
      return 'Walk';
    } else if (lowerName.contains('hike') || lowerName.contains('trek') || lowerName.contains('trail')) {
      return 'Hike';
    } else {
      return 'All'; // Default to 'All' for unknown sports
    }
  }

  // Categorize events into active and available
  void _categorizeEvents() {
    if (currentUserId == null) {
      _activeEvents = [];
      _availableEvents = _allEvents;
      return;
    }

    _activeEvents = _allEvents.where((event) => event.isActive).toList();
    _availableEvents = _allEvents.where((event) => !event.isActive).toList();
  }

  // Join an event
  Future<bool> joinEvent(String eventId) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('🔄 Joining event: $eventId');

      // Add current user to the event's participants
      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([currentUserId]),
      });

      // Update local state
      int eventIndex = _allEvents.indexWhere((event) => event.id == eventId);
      if (eventIndex != -1) {
        _allEvents[eventIndex].participants.add(currentUserId!);
        _allEvents[eventIndex].isActive = true;
        _categorizeEvents();
        notifyListeners();
      }

      print('✅ Successfully joined event: $eventId');
      return true;
    } catch (e) {
      print('❌ Error joining event: $e');
      return false;
    }
  }

  // Leave an event
  Future<bool> leaveEvent(String eventId) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('🔄 Leaving event: $eventId');

      // Remove current user from the event's participants
      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayRemove([currentUserId]),
      });

      // Update local state
      int eventIndex = _allEvents.indexWhere((event) => event.id == eventId);
      if (eventIndex != -1) {
        _allEvents[eventIndex].participants.remove(currentUserId);
        _allEvents[eventIndex].isActive = false;
        _categorizeEvents();
        notifyListeners();
      }

      print('✅ Successfully left event: $eventId');
      return true;
    } catch (e) {
      print('❌ Error leaving event: $e');
      return false;
    }
  }

  // Filter events by sport type
  List<Event> getEventsBySportType(String sportType) {
    if (sportType == 'All') {
      return _availableEvents;
    }
    return _availableEvents.where((event) => 
        event.containsSport(sportType) || event.sportType == sportType).toList();
  }

  // Get active events by sport type
  List<Event> getActiveEventsBySportType(String sportType) {
    if (sportType == 'All') {
      return _activeEvents;
    }
    return _activeEvents.where((event) => 
        event.containsSport(sportType) || event.sportType == sportType).toList();
  }

  // Start real-time listening for events
  void startListening() {
    print('🔄 Starting real-time events listener...');
    _eventsSubscription?.cancel(); // Cancel any existing subscription
    
    _eventsSubscription = _firestore
        .collection('events')
        .snapshots()
        .listen(
      (QuerySnapshot snapshot) async {
        print('🔄 Real-time events update received: ${snapshot.docs.length} events');
        await _processEventsSnapshot(snapshot);
      },
      onError: (error) {
        print('❌ Real-time events listener error: $error');
      },
    );
  }

  // Stop real-time listening
  void stopListening() {
    print('⏹️ Stopping real-time events listener...');
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
  }

  // Process events snapshot from real-time listener
  Future<void> _processEventsSnapshot(QuerySnapshot snapshot) async {
    try {
      List<Event> loadedEvents = [];

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Event event = await _convertFirebaseDataToEvent(doc.id, data);
          loadedEvents.add(event);
        } catch (e) {
          print('❌ Error converting real-time event ${doc.id}: $e');
        }
      }

      _allEvents = loadedEvents;
      _categorizeEvents();

      print('✅ Real-time update: ${_allEvents.length} events loaded');
      print('📊 Active: ${_activeEvents.length}, Available: ${_availableEvents.length}');

      notifyListeners();
    } catch (e) {
      print('❌ Error processing real-time events: $e');
    }
  }

  // Clear all local events (useful for logout)
  void clearEvents() {
    stopListening(); // Stop listening when clearing
    _allEvents = [];
    _activeEvents = [];
    _availableEvents = [];
    notifyListeners();
  }

  // Debug method to check Firebase collection directly
  Future<void> debugEventsCollection() async {
    try {
      print('🔍 DEBUG: Checking events collection directly...');
      
      // First check authentication
      User? currentUser = _auth.currentUser;
      print('🔍 Current user: ${currentUser?.uid ?? 'NOT AUTHENTICATED'}');
      print('🔍 User email: ${currentUser?.email ?? 'NO EMAIL'}');
      print('🔍 User anonymous: ${currentUser?.isAnonymous ?? 'UNKNOWN'}');
      
      if (currentUser == null) {
        print('❌ User is not authenticated! This is likely the issue.');
        return;
      }
      
      // Try to read a simple collection first
      print('🔍 Testing basic Firestore access...');
      await _firestore.collection('test').limit(1).get();
      print('✅ Basic Firestore access works');
      
      QuerySnapshot snapshot = await _firestore.collection('events').get();
      
      print('📊 Total documents in events collection: ${snapshot.docs.length}');
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('📄 Document ID: ${doc.id}');
        print('📄 Document data: $data');
        print('---');
      }
      
      // Also check for any business-specific collections
      print('🔍 Checking for business-events collection...');
      QuerySnapshot businessSnapshot = await _firestore.collection('business-events').get();
      print('📊 Total documents in business-events collection: ${businessSnapshot.docs.length}');
      
    } catch (e) {
      print('❌ Debug check failed: $e');
      if (e.toString().contains('permission-denied')) {
        print('❌ This is a permissions issue. Check:');
        print('   1. User authentication status');
        print('   2. Firebase security rules');
        print('   3. Firebase project configuration');
      }
    }
  }

  // Create a new event
  Future<String> createEvent(Map<String, dynamic> eventData) async {
    try {
      print('🔄 Creating new event...');
      print('📝 Event data being saved to Firebase:');
      print('   Name: ${eventData['name']}');
      print('   Team ID: ${eventData['teamId']}');
      print('   Is Team Event: ${eventData['isTeamEvent']}');
      print('   Created By: ${eventData['createdBy']}');
      print('   Sports: ${eventData['sports']}');
      print('   Start Date: ${eventData['startDate']}');
      print('   End Date: ${eventData['endDate']}');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Add the event to Firestore 'events' collection
      DocumentReference docRef = await _firestore.collection('events').add(eventData);
      
      print('✅ Event created successfully with ID: ${docRef.id}');
      print('🔗 Event saved to Firebase path: events/${docRef.id}');
      
      // Verify the event was saved by reading it back
      try {
        DocumentSnapshot savedEvent = await docRef.get();
        if (savedEvent.exists) {
          Map<String, dynamic> savedData = savedEvent.data() as Map<String, dynamic>;
          print('✅ Event verified in Firebase:');
          print('   Saved Name: ${savedData['name']}');
          print('   Saved Team ID: ${savedData['teamId']}');
          print('   Saved Is Team Event: ${savedData['isTeamEvent']}');
        } else {
          print('⚠️ Warning: Event document not found after creation');
        }
      } catch (e) {
        print('⚠️ Warning: Could not verify event was saved: $e');
      }
      
      // Reload events to include the new one (for general events, not team events)
      if (eventData['isTeamEvent'] != true) {
        await loadEvents();
      }
      
      return docRef.id;
    } catch (e) {
      print('❌ Error creating event: $e');
      print('❌ Error details: ${e.toString()}');
      if (e.toString().contains('permission-denied')) {
        print('❌ Firebase permission denied - check Firestore security rules');
        print('❌ Make sure events collection allows writes for authenticated users');
      }
      rethrow;
    }
  }

  // Get events for a specific team
  List<Event> getTeamEvents(String teamId) {
    return _allEvents.where((event) {
      // Check if event has teamId field or if businessId matches team ID
      return (event as dynamic).teamId == teamId || event.businessId == teamId;
    }).toList();
  }

  // Verify an event exists in Firebase (useful for debugging)
  Future<bool> verifyEventExists(String eventId) async {
    try {
      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
        print('✅ Event $eventId verified in Firebase:');
        print('   Name: ${data['name']}');
        print('   Team ID: ${data['teamId']}');
        print('   Is Team Event: ${data['isTeamEvent']}');
        return true;
      } else {
        print('❌ Event $eventId not found in Firebase');
        return false;
      }
    } catch (e) {
      print('❌ Error verifying event $eventId: $e');
      return false;
    }
  }

  // Get all events for debugging (includes team events)
  Future<List<Map<String, dynamic>>> getAllEventsForDebugging() async {
    try {
      QuerySnapshot allEventsSnapshot = await _firestore.collection('events').get();
      List<Map<String, dynamic>> allEvents = [];
      
      for (QueryDocumentSnapshot doc in allEventsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        allEvents.add(data);
      }
      
      print('🔍 Total events in Firebase: ${allEvents.length}');
      int teamEvents = allEvents.where((e) => e['isTeamEvent'] == true || e['teamId'] != null).length;
      print('🔍 Team events: $teamEvents');
      print('🔍 Business events: ${allEvents.length - teamEvents}');
      
      return allEvents;
    } catch (e) {
      print('❌ Error getting all events: $e');
      return [];
    }
  }

  // Load team events specifically for a team
  Future<List<Event>> loadTeamEvents(String teamId) async {
    try {
      print('🔄 Loading team events for team: $teamId');

      // Query events that belong to this team using teamId field
      QuerySnapshot teamEventsSnapshot = await _firestore
          .collection('events')
          .where('teamId', isEqualTo: teamId)
          .get();

      print('📄 Found ${teamEventsSnapshot.docs.length} team events for team: $teamId');

      // If no events found with teamId, also try with businessId (for backwards compatibility)
      if (teamEventsSnapshot.docs.isEmpty) {
        print('🔍 No events found with teamId, trying businessId for backwards compatibility...');
        teamEventsSnapshot = await _firestore
            .collection('events')
            .where('businessId', isEqualTo: teamId)
            .where('isTeamEvent', isEqualTo: true)
            .get();
        print('📄 Found ${teamEventsSnapshot.docs.length} team events using businessId');
      }

      List<Event> teamEvents = [];

      for (QueryDocumentSnapshot doc in teamEventsSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          print('📝 Processing team event: ${doc.id}');
          print('   Name: ${data['name']}');
          print('   Team ID: ${data['teamId']}');
          print('   Is Team Event: ${data['isTeamEvent']}');
          
          // Use the Event.fromMap factory constructor
          Event event = Event.fromMap(doc.id, data);
          
          // Check if current user has joined this event
          if (currentUserId != null && event.participants.contains(currentUserId)) {
            event.isActive = true;
          }
          
          teamEvents.add(event);
          
          print('✅ Successfully loaded team event: ${event.name}');
        } catch (e) {
          print('❌ Error converting team event ${doc.id}: $e');
          print('❌ Raw data: ${doc.data()}');
        }
      }

      print('✅ Successfully loaded ${teamEvents.length} team events for team: $teamId');
      
      // Log team events for debugging
      if (teamEvents.isNotEmpty) {
        print('📋 Team Events Summary:');
        for (Event event in teamEvents) {
          print('   - ${event.name} (${event.sportsDisplay}) - ${event.participantCount} participants');
        }
      } else {
        print('📋 No team events found for this team');
      }
      
      return teamEvents;
    } catch (e) {
      print('❌ Error loading team events for team $teamId: $e');
      print('❌ Error details: ${e.toString()}');
      return [];
    }
  }

  // Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated');
        return false;
      }

      print('🗑️ Attempting to delete event: $eventId');

      // First, verify the event exists and the user has permission to delete it
      DocumentSnapshot eventDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        print('❌ Event not found: $eventId');
        return false;
      }

      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      String eventCreatedBy = eventData['createdBy'] ?? '';

      // Check if the current user is the creator of the event
      if (eventCreatedBy != currentUser.uid) {
        print('❌ User does not have permission to delete event: $eventId');
        return false;
      }

      print('✅ User has permission to delete event: $eventId');

      // Delete related leaderboard data
      try {
        await _firestore
            .collection('leaderboards')
            .doc(eventId)
            .delete();
        print('✅ Deleted leaderboard data for event: $eventId');
      } catch (e) {
        print('⚠️ No leaderboard data found for event $eventId: $e');
      }

      // Delete the event document
      await _firestore
          .collection('events')
          .doc(eventId)
          .delete();

      print('✅ Successfully deleted event: $eventId');

      // Refresh the events list
      await loadEvents();

      return true;
    } catch (e) {
      print('❌ Error deleting event $eventId: $e');
      return false;
    }
  }
}
