import 'package:flutter/material.dart';
import 'activity_details_page.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  // Mock activities data
  final List<Activity> activities = [
    Activity(
      id: '1',
      userName: 'jindu yang',
      userInitial: 'j',
      activityType: 'Lunch Walk',
      date: 'July 20, 2025 at 11:38 AM',
      distance: '2.95 km',
      elevationGain: '69 m',
      time: '31m 11s',
      movingTime: '31:11',
      steps: '4,082',
      calories: '255 Cal',
      avgHeartRate: '128 bpm',
      userColor: Colors.blue,
    ),
    Activity(
      id: '2',
      userName: 'jindu yang',
      userInitial: 'j',
      activityType: 'Morning Run',
      date: 'July 19, 2025 at 7:15 AM',
      distance: '5.2 km',
      elevationGain: '45 m',
      time: '28m 35s',
      movingTime: '28:35',
      steps: '6,850',
      calories: '420 Cal',
      avgHeartRate: '156 bpm',
      userColor: Colors.blue,
    ),
    Activity(
      id: '3',
      userName: 'jindu yang',
      userInitial: 'j',
      activityType: 'Evening Bike Ride',
      date: 'July 18, 2025 at 6:30 PM',
      distance: '12.8 km',
      elevationGain: '120 m',
      time: '45m 22s',
      movingTime: '45:22',
      steps: '0',
      calories: '380 Cal',
      avgHeartRate: '142 bpm',
      userColor: Colors.blue,
    ),
    Activity(
      id: '4',
      userName: 'jindu yang',
      userInitial: 'j',
      activityType: 'Gym Session',
      date: 'July 17, 2025 at 8:00 AM',
      distance: '0 km',
      elevationGain: '0 m',
      time: '1h 15m',
      movingTime: '1:15:00',
      steps: '2,150',
      calories: '485 Cal',
      avgHeartRate: '135 bpm',
      userColor: Colors.blue,
    ),
    Activity(
      id: '5',
      userName: 'jindu yang',
      userInitial: 'j',
      activityType: 'Weekend Hike',
      date: 'July 16, 2025 at 9:45 AM',
      distance: '8.7 km',
      elevationGain: '350 m',
      time: '2h 18m',
      movingTime: '2:18:00',
      steps: '12,450',
      calories: '680 Cal',
      avgHeartRate: '148 bpm',
      userColor: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Activities',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: activities.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityCard(activity);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No activities yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your workouts and activities',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return GestureDetector(
      onTap: () {
        // Convert Activity to ActivityDetail for the details page
        final activityDetail = ActivityDetail(
          id: activity.id,
          userName: activity.userName,
          userInitial: activity.userInitial,
          activityType: activity.activityType,
          date: activity.date,
          distance: activity.distance,
          elevationGain: activity.elevationGain,
          movingTime: activity.movingTime,
          steps: activity.steps,
          calories: activity.calories,
          avgHeartRate: activity.avgHeartRate,
          userColor: activity.userColor,
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsPage(activity: activityDetail),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and timestamp
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activity.userColor,
                  ),
                  child: Center(
                    child: Text(
                      activity.userInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Activity title
            Text(
              activity.activityType,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Activity metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Distance',
                    activity.distance,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Elev Gain',
                    activity.elevationGain,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Time',
                    activity.time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class Activity {
  final String id;
  final String userName;
  final String userInitial;
  final String activityType;
  final String date;
  final String distance;
  final String elevationGain;
  final String time;
  final String movingTime;
  final String steps;
  final String calories;
  final String avgHeartRate;
  final Color userColor;

  Activity({
    required this.id,
    required this.userName,
    required this.userInitial,
    required this.activityType,
    required this.date,
    required this.distance,
    required this.elevationGain,
    required this.time,
    required this.movingTime,
    required this.steps,
    required this.calories,
    required this.avgHeartRate,
    required this.userColor,
  });
}
