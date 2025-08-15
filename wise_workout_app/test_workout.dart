import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/services/workout_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Check if user is authenticated
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ No authenticated user found');
    return;
  }
  
  print('✅ User authenticated: ${user.uid}');
  
  // Create a test workout
  final testActivity = WorkoutActivity(
    id: 'test_${DateTime.now().millisecondsSinceEpoch}',
    sportType: 'Walk',
    date: DateTime.now(),
    durationSeconds: 1800, // 30 minutes
    distanceKm: 2.5,
    steps: 3200,
    calories: 150,
    avgPace: 12.0, // 12 min/km
  );
  
  print('🏃‍♂️ Created test workout: ${testActivity.sportType}, ${testActivity.distanceKm}km, ${testActivity.formattedDuration}');
  
  // Add the workout through WorkoutService (this should trigger leaderboard sync)
  final workoutService = WorkoutService();
  await workoutService.addActivity(testActivity);
  
  print('✅ Test workout added successfully');
  print('🔍 Check team event leaderboards to see if data appears');
}
