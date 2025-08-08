import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/firebase_activity.dart';
import '../services/firebase_user_profile_service.dart';

class ActivityTestData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseUserProfileService _userProfileService = FirebaseUserProfileService();

  // Add sample activity data for testing
  static Future<void> addSampleActivities() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }

      // Get user profile for display name
      Map<String, dynamic>? userProfile = await _userProfileService.getUserProfile();
      String userName = userProfile?['displayName'] ?? 
                       userProfile?['username'] ?? 
                       currentUser.displayName ?? 
                       'Test User';
      String userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'T';

      List<FirebaseActivity> sampleActivities = [
        FirebaseActivity(
          id: 'test_activity_1',
          userId: currentUser.uid,
          userName: userName,
          userInitial: userInitial,
          activityType: 'Cycling',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          distance: '15.2 km',
          elevationGain: '120m',
          movingTime: '45m 30s',
          durationSeconds: 2730,
          distanceKm: 15.2,
          steps: '0',
          calories: '540 kcal',
          avgHeartRate: '142 bpm',
          avgPace: 2.98,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          metadata: {
            'source': 'test_data',
            'avgSpeed': 20.1,
          },
        ),
        FirebaseActivity(
          id: 'test_activity_2',
          userId: currentUser.uid,
          userName: userName,
          userInitial: userInitial,
          activityType: 'Run',
          date: DateTime.now().subtract(const Duration(days: 1)),
          distance: '5.8 km',
          elevationGain: '45m',
          movingTime: '28m 15s',
          durationSeconds: 1695,
          distanceKm: 5.8,
          steps: '7254',
          calories: '420 kcal',
          avgHeartRate: '165 bpm',
          avgPace: 4.87,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          metadata: {
            'source': 'test_data',
            'avgSpeed': 12.3,
          },
        ),
        FirebaseActivity(
          id: 'test_activity_3',
          userId: currentUser.uid,
          userName: userName,
          userInitial: userInitial,
          activityType: 'Walk',
          date: DateTime.now().subtract(const Duration(days: 2)),
          distance: '3.2 km',
          elevationGain: '15m',
          movingTime: '38m 45s',
          durationSeconds: 2325,
          distanceKm: 3.2,
          steps: '4180',
          calories: '180 kcal',
          avgHeartRate: '98 bpm',
          avgPace: 12.1,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          metadata: {
            'source': 'test_data',
            'avgSpeed': 4.95,
          },
        ),
        FirebaseActivity(
          id: 'test_activity_4',
          userId: currentUser.uid,
          userName: userName,
          userInitial: userInitial,
          activityType: 'Swimming',
          date: DateTime.now().subtract(const Duration(days: 3)),
          distance: '1.2 km',
          elevationGain: '0m',
          movingTime: '45m 12s',
          durationSeconds: 2712,
          distanceKm: 1.2,
          steps: '0',
          calories: '380 kcal',
          avgHeartRate: '135 bpm',
          avgPace: 37.6,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          metadata: {
            'source': 'test_data',
            'pool_length': 50,
            'strokes': 1456,
          },
        ),
        FirebaseActivity(
          id: 'test_activity_5',
          userId: currentUser.uid,
          userName: userName,
          userInitial: userInitial,
          activityType: 'Hiking',
          date: DateTime.now().subtract(const Duration(days: 5)),
          distance: '8.7 km',
          elevationGain: '480m',
          movingTime: '2h 15m',
          durationSeconds: 8100,
          distanceKm: 8.7,
          steps: '12450',
          calories: '650 kcal',
          avgHeartRate: '125 bpm',
          avgPace: 15.5,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          metadata: {
            'source': 'test_data',
            'trail_difficulty': 'moderate',
            'weather': 'sunny',
          },
        ),
      ];

      // Save each activity to Firebase
      for (FirebaseActivity activity in sampleActivities) {
        await _firestore
            .collection('activities')
            .doc(activity.id)
            .set(activity.toMap());
      }

      print('✅ Sample activities added to Firebase');
    } catch (e) {
      print('❌ Error adding sample activities: $e');
    }
  }

  // Clear test activities
  static Future<void> clearTestActivities() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }

      QuerySnapshot snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: currentUser.uid)
          .where('metadata.source', isEqualTo: 'test_data')
          .get();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Test activities cleared from Firebase');
    } catch (e) {
      print('❌ Error clearing test activities: $e');
    }
  }
}
