import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leaderboard_service.dart';
import 'firebase_activities_service.dart';
import 'firebase_events_service.dart';
import '../joined_events_state.dart';

class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  final List<WorkoutActivity> _activities = [];
  final LeaderboardService _leaderboardService = LeaderboardService();
  final FirebaseActivitiesService _firebaseActivitiesService = FirebaseActivitiesService();
  final JoinedEventsState _joinedEventsState = JoinedEventsState();

  List<WorkoutActivity> get activities => List.unmodifiable(_activities);

  Future<void> addActivity(WorkoutActivity activity) async {
    _activities.insert(0, activity); // Add to beginning (most recent first)
    notifyListeners();
    
    // Save to Firebase
    await _saveActivityToFirebase(activity);
    
    // Sync activity to all joined events' leaderboards
    await _syncActivityToLeaderboards(activity);
  }

  Future<void> _saveActivityToFirebase(WorkoutActivity activity) async {
    try {
      print('💾 Saving activity to Firebase...');
      bool success = await _firebaseActivitiesService.saveWorkoutActivity(activity);
      
      if (success) {
        print('✅ Activity saved to Firebase successfully');
      } else {
        print('❌ Failed to save activity to Firebase');
      }
    } catch (e) {
      print('❌ Error saving activity to Firebase: $e');
    }
  }

  Future<void> _syncActivityToLeaderboards(WorkoutActivity activity) async {
    try {
      // First ensure we have current joined events loaded
      await _ensureJoinedEventsLoaded();
      
      // Get list of joined event IDs
      List<String> joinedEventIds = _joinedEventsState.joinedEventIds.toList();
      
      print('🔍 Found ${joinedEventIds.length} joined events for syncing: $joinedEventIds');
      
      if (joinedEventIds.isNotEmpty) {
        print('🏆 Syncing activity ${activity.id} to ${joinedEventIds.length} event leaderboards');
        bool success = await _leaderboardService.syncActivityToLeaderboards(activity, joinedEventIds);
        
        if (success) {
          print('✅ Successfully synced activity to leaderboards');
        } else {
          print('❌ Failed to sync activity to some leaderboards');
        }
      } else {
        print('📭 No joined events found - checking for team events where user is participant');
        await _checkAndSyncToParticipatingEvents(activity);
      }
    } catch (e) {
      print('❌ Error syncing activity to leaderboards: $e');
    }
  }

  // Ensure joined events are loaded from Firebase
  /// Ensure joined events are loaded by discovering team events where user participates
  Future<void> _ensureJoinedEventsLoaded() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print('❌ No current user for joined events loading');
      return;
    }

    try {
      print('🔄 Ensuring joined events are loaded for user: $currentUserId');
      
      // Get current joined events
      final joinedState = JoinedEventsState();
      final currentJoinedEvents = Set<String>.from(joinedState.joinedEventIds);
      
      print('📊 Current joined events count: ${currentJoinedEvents.length}');
      print('📋 Current joined events: $currentJoinedEvents');
      
      // If already have joined events, no need to reload
      if (currentJoinedEvents.isNotEmpty) {
        print('✅ Joined events already loaded, skipping discovery');
        return;
      }
      
      // Get all events where user is a participant using raw Firebase data
      final eventsService = FirebaseEventsService();
      final allEvents = await eventsService.getAllEventsForDebugging();
      
      Set<String> discoveredEventIds = {};
      
      for (final eventData in allEvents) {
        final participants = eventData['participants'] as List<dynamic>? ?? [];
        final eventId = eventData['id'] as String?;
        final eventName = eventData['name'] as String? ?? 'Unknown';
        
        // Check if this is a team event using Firebase data
        bool isTeamEvent = eventData['isTeamEvent'] == true || eventData['teamId'] != null;
        
        if (isTeamEvent && eventId != null && participants.contains(currentUserId)) {
          discoveredEventIds.add(eventId);
          print('🎯 Discovered participation in team event: $eventName ($eventId)');
        }
      }
      
      print('🔍 Discovered ${discoveredEventIds.length} team events with user participation');
      
      if (discoveredEventIds.isNotEmpty) {
        // Add discovered events to joined events state
        for (String eventId in discoveredEventIds) {
          joinedState.joinEvent(eventId);
        }
        print('✅ Added ${discoveredEventIds.length} events to joined events state');
        print('📋 Updated joined events: ${joinedState.joinedEventIds}');
      } else {
        print('📋 No team event participation found for user');
      }
      
    } catch (e) {
      print('❌ Error ensuring joined events loaded: $e');
    }
  }

  // Check and sync to events where user is participating (fallback)
  Future<void> _checkAndSyncToParticipatingEvents(WorkoutActivity activity) async {
    try {
      final FirebaseEventsService eventsService = FirebaseEventsService();
      await eventsService.loadEvents();
      
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      // Get all events with raw data to check team event status
      final allEventsData = await eventsService.getAllEventsForDebugging();
      
      List<String> participatingEventIds = [];
      
      for (final eventData in allEventsData) {
        final participants = eventData['participants'] as List<dynamic>? ?? [];
        final eventId = eventData['id'] as String?;
        final eventName = eventData['name'] as String? ?? 'Unknown';
        
        // Check if this is a team event using Firebase data
        bool isTeamEvent = eventData['isTeamEvent'] == true || eventData['teamId'] != null;
        
        if (isTeamEvent && eventId != null && participants.contains(currentUserId)) {
          participatingEventIds.add(eventId);
          print('🎯 Found participation in team event: $eventName ($eventId)');
        }
      }
      
      if (participatingEventIds.isNotEmpty) {
        print('🏆 Direct syncing to ${participatingEventIds.length} participating team events');
        
        await _leaderboardService.syncActivityToLeaderboards(activity, participatingEventIds);
        
        // Also add to joined events state for future use
        final joinedState = JoinedEventsState();
        for (final eventId in participatingEventIds) {
          joinedState.joinEvent(eventId);
        }
      }
    } catch (e) {
      print('❌ Error in fallback sync: $e');
    }
  }

  void removeActivity(String activityId) {
    _activities.removeWhere((activity) => activity.id == activityId);
    notifyListeners();
  }

  void clearActivities() {
    _activities.clear();
    notifyListeners();
  }
}

class WorkoutActivity {
  final String id;
  final String sportType;
  final DateTime date;
  final int durationSeconds;
  final double distanceKm;
  final int steps;
  final int calories;
  final double avgPace; // min/km

  WorkoutActivity({
    required this.id,
    required this.sportType,
    required this.date,
    required this.durationSeconds,
    required this.distanceKm,
    required this.steps,
    required this.calories,
    required this.avgPace,
  });

  String get formattedDuration {
    int hours = durationSeconds ~/ 3600;
    int minutes = (durationSeconds % 3600) ~/ 60;
    int secs = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${secs}s';
    }
  }

  String get formattedDistance {
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  String get formattedCalories {
    return '$calories kcal';
  }

  String get formattedDate {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${months[date.month]} ${date.day}, ${date.year} at $displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String get activityTitle {
    final timeOfDay = date.hour;
    String timePrefix;
    
    if (timeOfDay < 12) {
      timePrefix = 'Morning';
    } else if (timeOfDay < 17) {
      timePrefix = 'Afternoon';
    } else {
      timePrefix = 'Evening';
    }
    
    return '$timePrefix $sportType';
  }

  IconData get sportIcon {
    switch (sportType) {
      case 'Walk':
        return Icons.directions_walk;
      case 'Run':
        return Icons.directions_run;
      case 'Cycling':
        return Icons.directions_bike;
      case 'Hiking':
        return Icons.terrain;
      case 'Swimming':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  Color get activityColor {
    switch (sportType) {
      case 'Walk':
        return Colors.green;
      case 'Run':
        return Colors.orange;
      case 'Cycling':
        return Colors.blue;
      case 'Hiking':
        return Colors.brown;
      case 'Swimming':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
