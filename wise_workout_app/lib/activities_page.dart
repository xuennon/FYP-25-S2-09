import 'package:flutter/material.dart';
import 'activity_details_page.dart';
import 'services/workout_service.dart';
import 'services/firebase_user_profile_service.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  final WorkoutService _workoutService = WorkoutService();
  final FirebaseUserProfileService _profileService = FirebaseUserProfileService();
  String _username = 'You';

  @override
  void initState() {
    super.initState();
    _workoutService.addListener(_onActivitiesChanged);
    _loadUsername();
  }

  @override
  void dispose() {
    _workoutService.removeListener(_onActivitiesChanged);
    super.dispose();
  }

  void _onActivitiesChanged() {
    setState(() {});
  }

  Future<void> _loadUsername() async {
    try {
      final username = await _profileService.getUsername();
      setState(() {
        _username = username;
      });
    } catch (e) {
      // Keep default 'You' if error loading username
      print('Error loading username: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activities = _workoutService.activities;
    
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

  Widget _buildActivityCard(WorkoutActivity activity) {
    return GestureDetector(
      onTap: () {
        // Convert WorkoutActivity to ActivityDetail for the details page
        final activityDetail = ActivityDetail(
          id: activity.id,
          userName: _username,
          userInitial: _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
          activityType: activity.activityTitle,
          date: activity.formattedDate,
          distance: activity.formattedDistance,
          elevationGain: '0 m', // Not tracked in current workout
          movingTime: activity.formattedDuration,
          steps: activity.steps.toString(),
          calories: activity.formattedCalories,
          avgHeartRate: '-- bpm', // Not tracked in current workout
          userColor: activity.activityColor,
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
                    color: activity.activityColor,
                  ),
                  child: Center(
                    child: Icon(
                      activity.sportIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(activity);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Activity title
            Text(
              activity.activityTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Activity metrics - showing Distance, Calories, and Time
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Distance',
                    activity.formattedDistance,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Calories',
                    activity.formattedCalories,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Time',
                    activity.formattedDuration,
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

  void _showDeleteConfirmation(WorkoutActivity activity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text('Are you sure you want to delete this ${activity.sportType} activity?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _workoutService.removeActivity(activity.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
