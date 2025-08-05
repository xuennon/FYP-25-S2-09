import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class FirebaseEventsService extends ChangeNotifier {
  static final FirebaseEventsService _instance =
      FirebaseEventsService._internal();
  factory FirebaseEventsService() => _instance;
  FirebaseEventsService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Event> _allEvents = [];
  List<Event> _activeEvents = [];
  List<Event> _availableEvents = [];
  bool _isLoading = false;

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
      QuerySnapshot eventsSnapshot =
          await _firestore.collection('events').get();

      print(
          '📄 Found ${eventsSnapshot.docs.length} documents in events collection');

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

          Event event = await _convertFirebaseDataToEvent(doc.id, data);
          loadedEvents.add(event);

          print('✅ Successfully converted event: ${event.name}');
        } catch (e) {
          print('❌ Error converting event ${doc.id}: $e');
          print('❌ Error details: ${e.toString()}');
        }
      }

      _allEvents = loadedEvents;
      _categorizeEvents();

      print('✅ Loaded ${_allEvents.length} events successfully');
      print(
          '📊 Active: ${_activeEvents.length}, Available: ${_availableEvents.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading events: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert Firebase data to Event object
  Future<Event> _convertFirebaseDataToEvent(
      String docId, Map<String, dynamic> data) async {
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
        // Mobile app format (Timestamp)
        startDate = (data['startDate'] as Timestamp).toDate();
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
        // Mobile app format (Timestamp)
        endDate = (data['endDate'] as Timestamp).toDate();
      } else {
        endDate = startDate.add(const Duration(hours: 2)); // Default 2 hours
      }

      // Extract basic fields
      String eventName = data['name'] ?? 'Unnamed Event';
      String businessId = data['businessId'] ?? data['uid'] ?? '';
      String businessName = data['businessName'] ?? 'Unknown Business';
      String description = data['description'] ?? '';

      // Determine sport type - use provided sportType or infer from name
      String sportType =
          data['sportType'] ?? _inferSportTypeFromName(eventName);

      // Handle participants
      List<String> participants = [];
      if (data['participants'] != null) {
        participants = List<String>.from(data['participants']);
      }

      // Handle other optional fields
      int? maxParticipants = data['maxParticipants'];

      // Handle createdAt
      DateTime createdAt;
      if (data['createdAt'] != null) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else {
        createdAt =
            DateTime.now(); // Default for business events without createdAt
      }

      print(
          '🎯 Converting event: $eventName (Sport: $sportType) by $businessName');
      print('📅 Event dates: ${startDate.toString()} to ${endDate.toString()}');

      return Event(
        id: docId,
        name: eventName,
        description: description,
        businessId: businessId,
        businessName: businessName,
        sportType: sportType,
        startDate: startDate,
        endDate: endDate,
        participants: participants,
        maxParticipants: maxParticipants,
        isActive: isJoined,
        createdAt: createdAt,
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

    if (lowerName.contains('run') ||
        lowerName.contains('jog') ||
        lowerName.contains('sprint')) {
      return 'Run';
    } else if (lowerName.contains('bike') ||
        lowerName.contains('cycle') ||
        lowerName.contains('ride')) {
      return 'Ride';
    } else if (lowerName.contains('swim') ||
        lowerName.contains('pool') ||
        lowerName.contains('water')) {
      return 'Swim';
    } else if (lowerName.contains('walk') || lowerName.contains('stroll')) {
      return 'Walk';
    } else if (lowerName.contains('hike') ||
        lowerName.contains('trek') ||
        lowerName.contains('trail')) {
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
    return _availableEvents
        .where((event) => event.sportType == sportType)
        .toList();
  }

  // Get active events by sport type
  List<Event> getActiveEventsBySportType(String sportType) {
    if (sportType == 'All') {
      return _activeEvents;
    }
    return _activeEvents
        .where((event) => event.sportType == sportType)
        .toList();
  }

  // Clear all local events (useful for logout)
  void clearEvents() {
    _allEvents = [];
    _activeEvents = [];
    _availableEvents = [];
    notifyListeners();
  }
}
