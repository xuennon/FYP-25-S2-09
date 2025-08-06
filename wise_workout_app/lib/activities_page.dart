import 'package:flutter/material.dart';
import 'activity_details_page.dart';
import 'services/workout_service.dart';
import 'services/firebase_activities_service.dart';
import 'services/activity_test_data.dart';
import 'models/firebase_activity.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> with WidgetsBindingObserver {
  final WorkoutService _workoutService = WorkoutService();
  final FirebaseActivitiesService _firebaseActivitiesService = FirebaseActivitiesService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workoutService.addListener(_onActivitiesChanged);
    _firebaseActivitiesService.addListener(_onActivitiesChanged);
    
    print('🚀 ActivitiesPage initState');
    print('👤 Current user on init: ${_firebaseActivitiesService.currentUserId}');
    
    _loadFirebaseActivities();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workoutService.removeListener(_onActivitiesChanged);
    _firebaseActivitiesService.removeListener(_onActivitiesChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload activities when app comes back to foreground
      _loadFirebaseActivities();
    }
  }

  void _onActivitiesChanged() {
    setState(() {});
  }

  Future<void> _loadFirebaseActivities() async {
    print('🔄 ActivitiesPage: Starting to load Firebase activities...');
    print('👤 Current user ID: ${_firebaseActivitiesService.currentUserId}');
    await _firebaseActivitiesService.loadUserActivities();
    print('📊 Activities loaded: ${_firebaseActivitiesService.userActivities.length}');
  }

  @override
  Widget build(BuildContext context) {
    final firebaseActivities = _firebaseActivitiesService.userActivities;
    final isLoading = _firebaseActivitiesService.isLoading;
    
    print('🏗️ ActivitiesPage building...');
    print('📱 isLoading: $isLoading');
    print('📊 firebaseActivities count: ${firebaseActivities.length}');
    print('👤 Current user ID: ${_firebaseActivitiesService.currentUserId}');
    
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
        actions: [
          // Debug button to check Firebase connection and data
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.blue),
            onPressed: () async {
              print('🔍 DEBUG: Checking Firebase activities...');
              print('👤 Current user: ${_firebaseActivitiesService.currentUserId}');
              
              // Force reload
              await _firebaseActivitiesService.loadUserActivities();
              
              // Check what we have
              final activities = _firebaseActivitiesService.userActivities;
              print('📊 Total activities found: ${activities.length}');
              
              for (int i = 0; i < activities.length && i < 3; i++) {
                final activity = activities[i];
                print('Activity $i: ${activity.activityType} - ${activity.userName} - ${activity.userId}');
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Found ${activities.length} activities. Check console for details.'),
                    backgroundColor: activities.isEmpty ? Colors.red : Colors.green,
                  ),
                );
              }
            },
          ),
          // Debug button to add sample activities
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
            onPressed: () async {
              await ActivityTestData.addSampleActivities();
              await _loadFirebaseActivities();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sample activities added!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadFirebaseActivities,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : firebaseActivities.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFirebaseActivities,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: firebaseActivities.length,
                    itemBuilder: (context, index) {
                      final activity = firebaseActivities[index];
                      return _buildFirebaseActivityCard(activity);
                    },
                  ),
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

  Widget _buildFirebaseActivityCard(FirebaseActivity activity) {
    return GestureDetector(
      onTap: () {
        // Convert FirebaseActivity to ActivityDetail for the details page
        final activityDetail = activity.toActivityDetail();
        
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
                    color: _getActivityColor(activity.activityType),
                  ),
                  child: Center(
                    child: Icon(
                      _getActivityIcon(activity.activityType),
                      color: Colors.white,
                      size: 24,
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
                        _formatActivityDate(activity.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showFirebaseDeleteConfirmation(activity);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Activity title
            Text(
              activity.activityType,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
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
                    'Calories',
                    activity.calories,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Time',
                    activity.movingTime,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'walk':
        return Colors.green;
      case 'run':
        return Colors.orange;
      case 'cycling':
        return Colors.blue;
      case 'hiking':
        return Colors.brown;
      case 'swimming':
        return Colors.cyan;
      default:
        return Colors.orange;
    }
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'walk':
        return Icons.directions_walk;
      case 'run':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'hiking':
        return Icons.terrain;
      case 'swimming':
        return Icons.pool;
      default:
        return Icons.directions_walk;
    }
  }

  String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return 'Today at $displayHour:${minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _showFirebaseDeleteConfirmation(FirebaseActivity activity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text('Are you sure you want to delete this ${activity.activityType} activity?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                bool success = await _firebaseActivitiesService.deleteActivity(activity.id);
                Navigator.of(context).pop();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity deleted from Firebase'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete activity'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
