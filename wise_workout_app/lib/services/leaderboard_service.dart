import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard.dart';
import '../models/event.dart';
import '../services/workout_service.dart';
import '../services/firebase_events_service.dart';
import '../services/firebase_user_profile_service.dart';

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseEventsService _eventsService = FirebaseEventsService();
  final FirebaseUserProfileService _userProfileService = FirebaseUserProfileService();

  // Get event details for metric information
  Future<Event?> _getEventDetails(String eventId) async {
    try {
      await _eventsService.loadEvents();
      return _eventsService.allEvents.firstWhere(
        (event) => event.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );
    } catch (e) {
      print('❌ Error getting event details for $eventId: $e');
      return null;
    }
  }

  // Get current participants of an event
  Future<List<String>> _getEventParticipants(String eventId) async {
    try {
      Event? event = await _getEventDetails(eventId);
      return event?.participants ?? [];
    } catch (e) {
      print('❌ Error getting event participants for $eventId: $e');
      return [];
    }
  }

  // Get leaderboard for a specific event
  Future<EventLeaderboard?> getEventLeaderboard(String eventId) async {
    try {
      print('🔍 Getting leaderboard for event: $eventId');
      
      // Get event details for metric information and current participants
      Event? event = await _getEventDetails(eventId);
      String? primaryMetric = event?.primaryMetric;
      String? primaryMetricDisplayName = event?.primaryMetricDisplayName;
      bool? isLowerBetter = event?.isLowerBetter;
      List<String> currentParticipants = event?.participants ?? [];
      
      print('📊 Event metric: $primaryMetric ($primaryMetricDisplayName), lower is better: $isLowerBetter');
      print('👥 Current participants: ${currentParticipants.length} users');
      
      DocumentSnapshot doc = await _firestore
          .collection('leaderboards')
          .doc(eventId)
          .get();

      print('📊 Leaderboard document exists: ${doc.exists}');
      
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        EventLeaderboard leaderboard = EventLeaderboard.fromMap(data);
        
        // Filter entries to only include current participants
        List<LeaderboardEntry> filteredEntries = leaderboard.entries
            .where((entry) => currentParticipants.contains(entry.userId))
            .toList();
        
        print('📊 Total entries: ${leaderboard.entries.length}, Filtered entries: ${filteredEntries.length}');
        
        // Create filtered leaderboard with current event metric info
        EventLeaderboard filteredLeaderboard = EventLeaderboard(
          eventId: leaderboard.eventId,
          entries: filteredEntries,
          lastUpdated: leaderboard.lastUpdated,
          primaryMetric: primaryMetric,
          isLowerBetter: isLowerBetter,
        );
        
        print('✅ Found leaderboard with ${filteredLeaderboard.entries.length} active entries');
        return filteredLeaderboard;
      }

      print('📭 No leaderboard found, returning empty leaderboard');
      // Return empty leaderboard if doesn't exist
      return EventLeaderboard(
        eventId: eventId,
        entries: [],
        lastUpdated: DateTime.now(),
        primaryMetric: primaryMetric,
        isLowerBetter: isLowerBetter,
      );
    } catch (e) {
      print('❌ Error getting leaderboard for event $eventId: $e');
      return null;
    }
  }

  // Add or update a leaderboard entry for an event
  Future<bool> addLeaderboardEntry(String eventId, LeaderboardEntry entry) async {
    try {
      // Get event details for metric information
      Event? event = await _getEventDetails(eventId);
      String? primaryMetric = event?.primaryMetric;
      bool? isLowerBetter = event?.isLowerBetter;
      
      // Get current leaderboard
      EventLeaderboard? leaderboard = await getEventLeaderboard(eventId);
      
      leaderboard ??= EventLeaderboard(
          eventId: eventId,
          entries: [],
          lastUpdated: DateTime.now(),
          primaryMetric: primaryMetric,
          isLowerBetter: isLowerBetter,
        );

      // Remove existing entry for this user if it exists
      leaderboard.entries.removeWhere((e) => e.userId == entry.userId);
      
      // Add new entry
      leaderboard.entries.add(entry);
      
      // Update last updated time with current metric info
      EventLeaderboard updatedLeaderboard = EventLeaderboard(
        eventId: leaderboard.eventId,
        entries: leaderboard.entries,
        lastUpdated: DateTime.now(),
        primaryMetric: primaryMetric,
        isLowerBetter: isLowerBetter,
      );

      // Save to Firebase
      await _firestore
          .collection('leaderboards')
          .doc(eventId)
          .set(updatedLeaderboard.toMap());

      print('✅ Successfully added leaderboard entry for user ${entry.userId} in event $eventId');
      return true;
    } catch (e) {
      print('❌ Error adding leaderboard entry: $e');
      return false;
    }
  }

  // Remove user's entries from an event's leaderboard
  Future<bool> removeUserFromEventLeaderboard(String eventId, String userId) async {
    try {
      print('🗑️ Removing user $userId from event $eventId leaderboard');
      
      // Get current leaderboard
      EventLeaderboard? leaderboard = await getEventLeaderboard(eventId);
      
      if (leaderboard == null || leaderboard.entries.isEmpty) {
        print('📭 No leaderboard found or already empty for event $eventId');
        return true; // Consider it successful if there's nothing to remove
      }

      // Count entries before removal
      int initialCount = leaderboard.entries.length;
      print('📊 Initial leaderboard entries: $initialCount');
      
      // Log all current entries before removal
      for (int i = 0; i < leaderboard.entries.length; i++) {
        var entry = leaderboard.entries[i];
        print('  Entry $i: userId=${entry.userId}, username=${entry.username}');
      }
      
      // Remove all entries for this user
      leaderboard.entries.removeWhere((entry) {
        bool shouldRemove = entry.userId == userId;
        if (shouldRemove) {
          print('  🎯 Found entry to remove: ${entry.username} (${entry.userId})');
        }
        return shouldRemove;
      });
      
      int finalCount = leaderboard.entries.length;
      int removedCount = initialCount - finalCount;
      
      print('🔢 Removed $removedCount entries for user $userId from event $eventId');
      print('📊 Final leaderboard entries: $finalCount');
      
      // Update leaderboard with removed entries
      EventLeaderboard updatedLeaderboard = EventLeaderboard(
        eventId: leaderboard.eventId,
        entries: leaderboard.entries,
        lastUpdated: DateTime.now(),
        primaryMetric: leaderboard.primaryMetric,
        isLowerBetter: leaderboard.isLowerBetter,
      );

      // Save to Firebase
      await _firestore
          .collection('leaderboards')
          .doc(eventId)
          .set(updatedLeaderboard.toMap());

      print('✅ Successfully updated Firebase with new leaderboard ($finalCount entries)');
      return true;
    } catch (e) {
      print('❌ Error removing user from leaderboard: $e');
      return false;
    }
  }

  // Sync activity to all joined events' leaderboards
  Future<bool> syncActivityToLeaderboards(WorkoutActivity activity, List<String> joinedEventIds) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return false;
      }

      // Get user profile info from Firestore user profile service
      Map<String, dynamic>? userProfile = await _userProfileService.getUserProfile();
      String username = userProfile?['displayName'] ?? 
                       userProfile?['username'] ?? 
                       currentUser.displayName ?? 
                       'Unknown User';
      String userInitial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
      
      print('👤 Leaderboard: User info: $username ($userInitial)');

      // Create leaderboard entry from activity
      LeaderboardEntry entry = LeaderboardEntry(
        userId: currentUser.uid,
        username: username,
        userInitial: userInitial,
        metrics: {
          'durationSeconds': activity.durationSeconds,
          'distanceKm': activity.distanceKm,
          'avgPace': activity.avgPace,
          'steps': activity.steps,
          'calories': activity.calories,
          'sportType': activity.sportType,
        },
        recordedAt: activity.date,
        activityId: activity.id,
      );

      // Add entry to all joined events' leaderboards
      bool allSuccessful = true;
      for (String eventId in joinedEventIds) {
        bool success = await addLeaderboardEntry(eventId, entry);
        if (!success) {
          allSuccessful = false;
        }
      }

      return allSuccessful;
    } catch (e) {
      print('❌ Error syncing activity to leaderboards: $e');
      return false;
    }
  }

  // Get user's rank in a specific event
  Future<int> getUserRankInEvent(String eventId, String userId) async {
    try {
      EventLeaderboard? leaderboard = await getEventLeaderboard(eventId);
      if (leaderboard != null) {
        return leaderboard.getUserRank(userId);
      }
      return -1;
    } catch (e) {
      print('Error getting user rank: $e');
      return -1;
    }
  }

  // Stream leaderboard updates for real-time updates
  Stream<EventLeaderboard?> streamEventLeaderboard(String eventId) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Check if user is authenticated
      if (user == null) {
        print('⚠️ No authenticated user - returning empty leaderboard stream');
        return Stream.value(null);
      }
      
      print('🔄 Starting leaderboard stream for event: $eventId');
      print('👤 Current user: ${user.uid} (Anonymous: ${user.isAnonymous})');

      return _firestore
          .collection('leaderboards')
          .doc(eventId)
          .snapshots()
          .asyncMap((snapshot) async {
        try {
          print('📡 Leaderboard snapshot received for event $eventId');
          print('📄 Document exists: ${snapshot.exists}');
          
          // Get event details for metric information and current participants
          Event? event = await _getEventDetails(eventId);
          String? primaryMetric = event?.primaryMetric;
          bool? isLowerBetter = event?.isLowerBetter;
          List<String> currentParticipants = event?.participants ?? [];
          
          print('👥 Current participants: ${currentParticipants.length} users');
          
          if (snapshot.exists && snapshot.data() != null) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            EventLeaderboard leaderboard = EventLeaderboard.fromMap(data);
            
            // Filter entries to only include current participants
            List<LeaderboardEntry> filteredEntries = leaderboard.entries
                .where((entry) => currentParticipants.contains(entry.userId))
                .toList();
            
            print('📊 Total entries: ${leaderboard.entries.length}, Filtered entries: ${filteredEntries.length}');
            
            // Create filtered leaderboard with current event metric info
            EventLeaderboard filteredLeaderboard = EventLeaderboard(
              eventId: leaderboard.eventId,
              entries: filteredEntries,
              lastUpdated: leaderboard.lastUpdated,
              primaryMetric: primaryMetric,
              isLowerBetter: isLowerBetter,
            );
            
            print('✅ Leaderboard loaded with ${filteredLeaderboard.entries.length} active entries, metric: $primaryMetric');
            return filteredLeaderboard;
          }
          
          print('📭 No leaderboard data found, returning empty leaderboard');
          return EventLeaderboard(
            eventId: eventId,
            entries: [],
            lastUpdated: DateTime.now(),
            primaryMetric: primaryMetric,
            isLowerBetter: isLowerBetter,
          );
        } catch (e) {
          print('❌ Error processing leaderboard snapshot: $e');
          return EventLeaderboard(
            eventId: eventId,
            entries: [],
            lastUpdated: DateTime.now(),
          );
        }
      });
    } catch (e) {
      print('❌ Error in streamEventLeaderboard: $e');
      return Stream.value(null);
    }
  }
}
