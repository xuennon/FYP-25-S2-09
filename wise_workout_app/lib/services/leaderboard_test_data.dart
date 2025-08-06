import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard.dart';

class LeaderboardTestData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add sample leaderboard data for testing
  static Future<void> addSampleLeaderboardData(String eventId) async {
    try {
      List<LeaderboardEntry> sampleEntries = [
        LeaderboardEntry(
          userId: 'user1',
          userName: 'núria trulls i serra',
          userInitial: 'N',
          metrics: {
            'durationSeconds': 19417, // 5h 37m 22s in seconds
            'distanceKm': 10.0,
            'avgPace': 5.6,
            'steps': 12000,
            'calories': 450,
            'sportType': 'cycling',
          },
          recordedAt: DateTime.now().subtract(const Duration(hours: 2)),
          activityId: 'activity1',
        ),
        LeaderboardEntry(
          userId: 'user2',
          userName: 'Frankie Law',
          userInitial: 'F',
          metrics: {
            'durationSeconds': 8680, // 2h 24m 40s in seconds
            'distanceKm': 10.0,
            'avgPace': 4.3,
            'steps': 13500,
            'calories': 520,
            'sportType': 'cycling',
          },
          recordedAt: DateTime.now().subtract(const Duration(hours: 1)),
          activityId: 'activity2',
        ),
        LeaderboardEntry(
          userId: 'user3',
          userName: 'Sabrina Ma',
          userInitial: 'S',
          metrics: {
            'durationSeconds': 6484, // 1h 48m 4s in seconds
            'distanceKm': 10.0,
            'avgPace': 3.9,
            'steps': 14200,
            'calories': 580,
            'sportType': 'cycling',
          },
          recordedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          activityId: 'activity3',
        ),
        LeaderboardEntry(
          userId: 'user4',
          userName: 'Liam McGuinness',
          userInitial: 'L',
          metrics: {
            'durationSeconds': 6421, // 1h 47m 1s in seconds
            'distanceKm': 10.0,
            'avgPace': 3.85,
            'steps': 14500,
            'calories': 590,
            'sportType': 'cycling',
          },
          recordedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          activityId: 'activity4',
        ),
        LeaderboardEntry(
          userId: 'user5',
          userName: 'Martin Rumens',
          userInitial: 'M',
          metrics: {
            'durationSeconds': 4504, // 1h 15m 4s in seconds
            'distanceKm': 10.0,
            'avgPace': 2.7,
            'steps': 15000,
            'calories': 620,
            'sportType': 'cycling',
          },
          recordedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          activityId: 'activity5',
        ),
        LeaderboardEntry(
          userId: 'user6',
          userName: 'Daria Drab',
          userInitial: 'D',
          metrics: {
            'durationSeconds': 4472, // 1h 14m 32s in seconds
            'distanceKm': 10.0,
            'avgPace': 2.68,
            'steps': 15200,
            'calories': 625,
            'sportType': 'cycling',
          },
          recordedAt: DateTime.now().subtract(const Duration(minutes: 8)),
          activityId: 'activity6',
        ),
        LeaderboardEntry(
          userId: 'user7',
          userName: 'Luis DEMÓFILO',
          userInitial: 'L',
          metrics: {
            'durationSeconds': 4452, // 1h 14m 12s in seconds
            'distanceKm': 10.0,
            'avgPace': 2.67,
            'steps': 15300,
            'calories': 630,
            'sportType': 'cycling',
          },
          recordedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          activityId: 'activity7',
        ),
        LeaderboardEntry(
          userId: 'user8',
          userName: 'Alex Vdovushkin',
          userInitial: 'A',
          metrics: {
            'durationSeconds': 4435, // 1h 13m 55s in seconds
            'distanceKm': 10.0,
            'avgPace': 2.66,
            'steps': 15400,
            'calories': 635,
            'sportType': 'cycling',
          },
          recordedAt: DateTime.now().subtract(const Duration(minutes: 2)),
          activityId: 'activity8',
        ),
      ];

      EventLeaderboard leaderboard = EventLeaderboard(
        eventId: eventId,
        entries: sampleEntries,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('eventLeaderboards')
          .doc(eventId)
          .set(leaderboard.toMap());

      print('✅ Sample leaderboard data added for event $eventId');
    } catch (e) {
      print('❌ Error adding sample leaderboard data: $e');
    }
  }

  // Clear leaderboard data
  static Future<void> clearLeaderboardData(String eventId) async {
    try {
      await _firestore
          .collection('eventLeaderboards')
          .doc(eventId)
          .delete();

      print('✅ Leaderboard data cleared for event $eventId');
    } catch (e) {
      print('❌ Error clearing leaderboard data: $e');
    }
  }
}
