import 'package:flutter/material.dart';
import 'search_page.dart';
import 'settings_page.dart';
import 'friend_list_page.dart';
import 'event_page.dart';
import 'activities_page.dart';
import 'widgets/user_avatar.dart';
import 'all_teams_page.dart';
import 'edit_profile_page.dart';
import 'my_posts_page.dart';
import 'all_events_page.dart';
import 'feedback_page.dart';
import 'services/firebase_user_profile_service.dart';
import 'services/firebase_friend_service.dart';
import 'workout_record_page.dart';
import 'enrolled_programs_page.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final FirebaseUserProfileService _profileService = FirebaseUserProfileService();
  final FirebaseFriendService _friendService = FirebaseFriendService();
  
  String _username = 'User';
  bool _isLoading = true;
  bool _profileWasUpdated = false; // Track if profile was updated
  int _followingCount = 0;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Load username and follow counts in parallel
      final results = await Future.wait([
        _profileService.getUsername(),
        _friendService.getFollowCounts(),
      ]);
      
      String username = results[0] as String;
      Map<String, int> followCounts = results[1] as Map<String, int>;
      
      setState(() {
        _username = username;
        _followingCount = followCounts['following'] ?? 0;
        _followersCount = followCounts['followers'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading username: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Only Search and Settings at top right
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header - moved to top left
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture with initial
              const UserAvatar(
                radius: 40,
                fontSize: 36,
              ),
              const SizedBox(width: 16),
              
              // Username on the right side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Following/Followers Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FriendListPage()),
                  );
                },
                child: Column(
                  children: [
                    const Text(
                      'Following',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_followingCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FriendListPage()),
                  );
                },
                child: Column(
                  children: [
                    const Text(
                      'Followers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_followersCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Edit Profile Button - moved below following/followers
          Center(
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
                // Refresh username when returning from edit page
                await _loadUserProfile();
                
                // Track if profile was updated but stay on this page
                if (result == true) {
                  _profileWasUpdated = true;
                  // Show success message and stay on profile page
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.edit, size: 16, color: Colors.orange),
              label: const Text(
                'Edit',
                style: TextStyle(color: Colors.orange, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Menu Items
          _buildMenuItem(
            icon: Icons.timeline,
            title: 'Activities',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActivitiesPage()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.article,
            title: 'Posts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPostsPage()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.fitness_center,
            title: 'Training Programs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EnrolledProgramsPage()),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Clubs and Events Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Teams', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllTeamsPage()),
                  );
                }),
                const SizedBox(height: 16),
                _buildSectionHeader('Events', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllEventsPage()),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Feedback Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Interested in sharing your feedback?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedbackPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Give Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: _handleBackNavigation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, color: Colors.grey[600], size: 28),
                const Text(
                  'Home',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendListPage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people, color: Colors.grey[600], size: 28),
                const Text(
                  'Friend',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutRecordPage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center, color: Colors.grey[600], size: 28),
                const Text(
                  'Record',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventPage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 28),
                const Text(
                  'Event',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Current page - Profile (highlighted)
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, color: Colors.orange, size: 28), // Orange to show it's active
              Text(
                'Profile',
                style: TextStyle(fontSize: 12, color: Colors.orange), // Orange to show it's active
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Handle back navigation to pass result
  void _handleBackNavigation() {
    Navigator.of(context).pop(_profileWasUpdated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileSection(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                margin: const EdgeInsets.only(top: 20),
                child: _buildProfileContent(),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }
}
