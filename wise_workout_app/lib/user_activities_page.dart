import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/firebase_activity.dart';
import 'activity_details_page.dart';

class UserActivitiesPage extends StatefulWidget {
  final String username;
  final String userId;
  
  const UserActivitiesPage({
    super.key, 
    required this.username,
    required this.userId,
  });

  @override
  State<UserActivitiesPage> createState() => _UserActivitiesPageState();
}

class _UserActivitiesPageState extends State<UserActivitiesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FirebaseActivity> _userActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserActivities();
  }

  Future<void> _loadUserActivities() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('🔄 Loading activities for user: ${widget.username} (${widget.userId})');

      // First, let's check if there are any activities at all
      QuerySnapshot allActivitiesSnapshot = await _firestore
          .collection('activities')
          .get();
      print('📊 Total activities in database: ${allActivitiesSnapshot.docs.length}');

      // Also check current user's activities to verify Firebase access
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        QuerySnapshot currentUserActivities = await _firestore
            .collection('activities')
            .where('userId', isEqualTo: currentUserId)
            .get();
        print('📊 Current user ($currentUserId) has ${currentUserActivities.docs.length} activities');
      }

      // Get activities for this specific user
      QuerySnapshot querySnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: widget.userId)
          .get(); // Removed orderBy temporarily to avoid index requirement

      print('📊 Activities found for user ${widget.userId}: ${querySnapshot.docs.length}');

      // Debug: Let's see what activities exist for any user to understand the data structure
      if (allActivitiesSnapshot.docs.isNotEmpty) {
        print('🔍 Sample activity data structure:');
        for (int i = 0; i < allActivitiesSnapshot.docs.length && i < 3; i++) {
          var sampleDoc = allActivitiesSnapshot.docs[i];
          Map<String, dynamic> sampleData = sampleDoc.data() as Map<String, dynamic>;
          print('   Activity ${i + 1}: userId=${sampleData['userId']}, activityType=${sampleData['activityType']}, id=${sampleDoc.id}');
        }
      }

      List<FirebaseActivity> activities = [];
      for (var doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print('🔍 Processing activity: ${doc.id} with userId: ${data['userId']}');
          FirebaseActivity activity = FirebaseActivity.fromMap(data);
          activities.add(activity);
        } catch (e) {
          print('❌ Error parsing activity ${doc.id}: $e');
          print('❌ Activity data: ${doc.data()}');
        }
      }

      setState(() {
        _userActivities = activities;
        _isLoading = false;
      });

      print('✅ Loaded ${_userActivities.length} activities for ${widget.username}');
      
      if (_userActivities.isEmpty) {
        print('🔍 No activities found. This could mean:');
        print('   - User ${widget.username} (${widget.userId}) has no activities');
        print('   - Firebase rules are preventing access');
        print('   - Activities use a different userId format');
      }
    } catch (e) {
      print('❌ Error loading user activities: $e');
      print('❌ Error details: ${e.runtimeType}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '${widget.username}\'s Activities',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : _userActivities.isEmpty
              ? _buildEmptyState()
              : _buildActivitiesList(),
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
            'No Activities Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.username} hasn\'t recorded any activities yet.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {
    return RefreshIndicator(
      onRefresh: _loadUserActivities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userActivities.length,
        itemBuilder: (context, index) {
          final activity = _userActivities[index];
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildActivityCard(FirebaseActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailsPage(activity: activity.toActivityDetail()),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Header
                Row(
                  children: [
                    // Activity Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getActivityColor(activity.activityType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getActivityIcon(activity.activityType),
                        color: _getActivityColor(activity.activityType),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Activity Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.activityType.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(activity.createdAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Duration
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDuration(Duration(seconds: activity.durationSeconds)),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Activity Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (activity.distanceKm > 0) ...[
                      _buildStatItem('Distance', '${activity.distanceKm.toStringAsFixed(2)} km'),
                    ],
                    if (_parseCalories(activity.calories) > 0) ...[
                      _buildStatItem('Calories', activity.calories),
                    ],
                    if (_parseSteps(activity.steps) > 0) ...[
                      _buildStatItem('Steps', activity.steps),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Helper methods to parse string values to numbers
  int _parseSteps(String stepsStr) {
    try {
      return int.parse(stepsStr.replaceAll(',', '').replaceAll(' steps', ''));
    } catch (e) {
      return 0;
    }
  }

  int _parseCalories(String caloriesStr) {
    try {
      return int.parse(caloriesStr.replaceAll(' kcal', '').replaceAll(',', ''));
    } catch (e) {
      return 0;
    }
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'run':
      case 'running':
        return Icons.directions_run;
      case 'walk':
      case 'walking':
        return Icons.directions_walk;
      case 'cycle':
      case 'cycling':
      case 'bike':
      case 'biking':
        return Icons.directions_bike;
      case 'swim':
      case 'swimming':
        return Icons.pool;
      case 'gym':
      case 'workout':
        return Icons.fitness_center;
      case 'yoga':
        return Icons.self_improvement;
      case 'dance':
      case 'dancing':
        return Icons.music_note;
      case 'hiking':
      case 'hike':
        return Icons.hiking;
      default:
        return Icons.sports;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'run':
      case 'running':
        return Colors.red;
      case 'walk':
      case 'walking':
        return Colors.green;
      case 'cycle':
      case 'cycling':
      case 'bike':
      case 'biking':
        return Colors.blue;
      case 'swim':
      case 'swimming':
        return Colors.cyan;
      case 'gym':
      case 'workout':
        return Colors.purple;
      case 'yoga':
        return Colors.pink;
      case 'dance':
      case 'dancing':
        return Colors.deepPurple;
      case 'hiking':
      case 'hike':
        return Colors.brown;
      default:
        return Colors.orange;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
