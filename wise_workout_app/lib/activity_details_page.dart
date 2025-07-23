import 'package:flutter/material.dart';

class ActivityDetailsPage extends StatelessWidget {
  final ActivityDetail activity;

  const ActivityDetailsPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and timestamp
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activity.userColor,
                  ),
                  child: Center(
                    child: Text(
                      activity.userInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.date,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Activity title
            Text(
              activity.activityType,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Activity metrics in 2x3 grid
            Column(
              children: [
                // First row: Distance and Elevation Gain
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailedMetric(
                        'Distance',
                        activity.distance,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildDetailedMetric(
                        'Elevation Gain',
                        activity.elevationGain,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Second row: Moving Time and Steps
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailedMetric(
                        'Moving Time',
                        activity.movingTime,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildDetailedMetric(
                        'Steps',
                        activity.steps,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Third row: Calories and Avg Heart Rate
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailedMetric(
                        'Calories',
                        activity.calories,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildDetailedMetric(
                        'Avg Heart Rate',
                        activity.avgHeartRate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class ActivityDetail {
  final String id;
  final String userName;
  final String userInitial;
  final String activityType;
  final String date;
  final String distance;
  final String elevationGain;
  final String movingTime;
  final String steps;
  final String calories;
  final String avgHeartRate;
  final Color userColor;

  ActivityDetail({
    required this.id,
    required this.userName,
    required this.userInitial,
    required this.activityType,
    required this.date,
    required this.distance,
    required this.elevationGain,
    required this.movingTime,
    required this.steps,
    required this.calories,
    required this.avgHeartRate,
    required this.userColor,
  });
}
