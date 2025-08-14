import 'package:flutter/material.dart';
import 'package:wise_workout_app/activity_details_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Details Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ActivityDetailsPage(
        activity: ActivityDetail(
          id: '1',
          userName: 'John Smith',
          userInitial: 'JS',
          activityType: 'Running',
          date: 'Today, 2:30 PM',
          distance: '5.2 km',
          elevationGain: '120 m',
          movingTime: '32:45',
          steps: '6,420',
          calories: '420 kcal',
          avgHeartRate: '145 bpm',
          userColor: Colors.blue,
        ),
      ),
    );
  }
}
