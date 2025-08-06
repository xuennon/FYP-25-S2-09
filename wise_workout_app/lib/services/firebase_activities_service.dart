import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/firebase_activity.dart';
import 'firebase_user_profile_service.dart';
import 'workout_service.dart';

class FirebaseActivitiesService extends ChangeNotifier {
  static final FirebaseActivitiesService _instance = FirebaseActivitiesService._internal();
  factory FirebaseActivitiesService() => _instance;
  FirebaseActivitiesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseUserProfileService _userProfileService = FirebaseUserProfileService();

  List<FirebaseActivity> _userActivities = [];
  List<FirebaseActivity> _allActivities = [];
  bool _isLoading = false;

  List<FirebaseActivity> get userActivities => List.unmodifiable(_userActivities);
  List<FirebaseActivity> get allActivities => List.unmodifiable(_allActivities);
  bool get isLoading => _isLoading;
  String? get currentUserId => _auth.currentUser?.uid;

  // Save activity to Firebase
  Future<bool> saveActivity(FirebaseActivity activity) async {
    try {
      print('🏃 Saving activity to Firebase: ${activity.activityType}');
      print('📄 Activity data: ${activity.toMap()}');
      
      // Save to Firestore
      await _firestore
          .collection('activities')
          .doc(activity.id)
          .set(activity.toMap());

      print('✅ Activity saved successfully to Firebase with ID: ${activity.id}');
      
      // Add to local cache
      _userActivities.insert(0, activity);
      _allActivities.insert(0, activity);
      notifyListeners();
      
      return true;
    } catch (e) {
      print('❌ Error saving activity to Firebase: $e');
      return false;
    }
  }

  // Load user's activities from Firebase
  Future<void> loadUserActivities() async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user found');
        return;
      }

      _isLoading = true;
      notifyListeners();

      print('🔄 Loading user activities from Firebase...');

      QuerySnapshot snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      List<FirebaseActivity> activities = [];
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          FirebaseActivity activity = FirebaseActivity.fromMap(data);
          activities.add(activity);
        } catch (e) {
          print('❌ Error parsing activity ${doc.id}: $e');
        }
      }

      _userActivities = activities;
      print('✅ Loaded ${_userActivities.length} user activities');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading user activities: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all activities (for social features)
  Future<void> loadAllActivities({int limit = 50}) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Loading all activities from Firebase...');

      QuerySnapshot snapshot = await _firestore
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      List<FirebaseActivity> activities = [];
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          FirebaseActivity activity = FirebaseActivity.fromMap(data);
          activities.add(activity);
        } catch (e) {
          print('❌ Error parsing activity ${doc.id}: $e');
        }
      }

      _allActivities = activities;
      print('✅ Loaded ${_allActivities.length} activities');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading all activities: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream user activities for real-time updates
  Stream<List<FirebaseActivity>> streamUserActivities() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<FirebaseActivity> activities = [];
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          FirebaseActivity activity = FirebaseActivity.fromMap(data);
          activities.add(activity);
        } catch (e) {
          print('❌ Error parsing activity ${doc.id}: $e');
        }
      }
      return activities;
    });
  }

  // Delete activity
  Future<bool> deleteActivity(String activityId) async {
    try {
      print('🗑️ Deleting activity: $activityId');
      
      await _firestore
          .collection('activities')
          .doc(activityId)
          .delete();

      // Remove from local cache
      _userActivities.removeWhere((activity) => activity.id == activityId);
      _allActivities.removeWhere((activity) => activity.id == activityId);
      notifyListeners();

      print('✅ Activity deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting activity: $e');
      return false;
    }
  }

  // Get activity by ID
  Future<FirebaseActivity?> getActivity(String activityId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return FirebaseActivity.fromMap(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting activity: $e');
      return null;
    }
  }

  // Convert WorkoutActivity to FirebaseActivity and save
  Future<bool> saveWorkoutActivity(WorkoutActivity workoutActivity) async {
    try {
      print('🔄 Converting WorkoutActivity to FirebaseActivity...');
      print('📋 WorkoutActivity data: ${workoutActivity.sportType}, ${workoutActivity.durationSeconds}s, ${workoutActivity.distanceKm}km');
      
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return false;
      }

      // Get user profile for display name and initial
      Map<String, dynamic>? userProfile = await _userProfileService.getUserProfile();
      String userName = userProfile?['displayName'] ?? 
                       userProfile?['username'] ?? 
                       currentUser.displayName ?? 
                       'User';
      String userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

      print('👤 User info: $userName ($userInitial)');

      // Convert WorkoutActivity to FirebaseActivity
      FirebaseActivity firebaseActivity = FirebaseActivity(
        id: workoutActivity.id,
        userId: currentUser.uid,
        userName: userName,
        userInitial: userInitial,
        activityType: workoutActivity.sportType,
        date: workoutActivity.date,
        distance: workoutActivity.formattedDistance,
        elevationGain: '0m', // TODO: Add elevation tracking
        movingTime: workoutActivity.formattedDuration,
        durationSeconds: workoutActivity.durationSeconds,
        distanceKm: workoutActivity.distanceKm,
        steps: workoutActivity.steps.toString(),
        calories: workoutActivity.formattedCalories,
        avgHeartRate: 'N/A', // TODO: Add heart rate tracking
        avgPace: workoutActivity.avgPace,
        createdAt: DateTime.now(),
        metadata: {
          'source': 'workout_record_page',
          'originalSportType': workoutActivity.sportType,
        },
      );

      print('🔄 Converted to FirebaseActivity, saving...');
      return await saveActivity(firebaseActivity);
    } catch (e) {
      print('❌ Error converting and saving workout activity: $e');
      return false;
    }
  }

  // Get activities for a specific user (for social features)
  Future<List<FirebaseActivity>> getUserActivities(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      List<FirebaseActivity> activities = [];
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          FirebaseActivity activity = FirebaseActivity.fromMap(data);
          activities.add(activity);
        } catch (e) {
          print('❌ Error parsing activity ${doc.id}: $e');
        }
      }

      return activities;
    } catch (e) {
      print('❌ Error loading user activities: $e');
      return [];
    }
  }

  // Clear local cache
  void clearCache() {
    _userActivities.clear();
    _allActivities.clear();
    notifyListeners();
  }
}
