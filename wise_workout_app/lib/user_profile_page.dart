import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_friend_service.dart';
import 'activities_page.dart';
import 'user_posts_page.dart';
import 'user_teams_page.dart';
import 'user_events_page.dart';

class UserProfilePage extends StatefulWidget {
  final String username;
  
  const UserProfilePage({super.key, required this.username});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isFollowing = false;
  int _postsCount = 0;
  int _followingCount = 0;
  int _followersCount = 0;
  int _teamsCount = 0;
  int _eventsCount = 0;
  String? _targetUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get user ID by username
      final userData = await _friendService.searchUsers(widget.username);
      if (userData.isNotEmpty) {
        _targetUserId = userData[0]['userId'];
        
        // Load follow status
        final isFollowing = await _friendService.isFollowing(_targetUserId!);
        
        // Get real posts count for this user
        int postsCount = await _getPostsCountForUser(_targetUserId!);
        
        // Get real following/followers count for this user
        Map<String, int> followCounts = await _getFollowCountsForUser(_targetUserId!);
        
        // Get real teams and events count for this user
        int teamsCount = await _getTeamsCountForUser(_targetUserId!);
        int eventsCount = await _getEventsCountForUser(_targetUserId!);
        
        setState(() {
          _isFollowing = isFollowing;
          _postsCount = postsCount;
          _followingCount = followCounts['following'] ?? 0;
          _followersCount = followCounts['followers'] ?? 0;
          _teamsCount = teamsCount;
          _eventsCount = eventsCount;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Get posts count for a specific user
  Future<int> _getPostsCountForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting posts count: $e');
      return 0;
    }
  }

  // Get follow counts for a specific user
  Future<Map<String, int>> _getFollowCountsForUser(String userId) async {
    try {
      // Get following count
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      // Get followers count
      final followersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();

      return {
        'following': followingSnapshot.docs.length,
        'followers': followersSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting follow counts: $e');
      return {'following': 0, 'followers': 0};
    }
  }

  // Get teams count for a specific user (both created and joined teams)
  Future<int> _getTeamsCountForUser(String userId) async {
    print('🔍 Getting teams count for user: $userId');
    try {
      final querySnapshot = await _firestore
          .collection('teams')
          .where('members', arrayContains: userId)
          .get();
      print('📊 Found ${querySnapshot.docs.length} teams for user $userId in profile count');
      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ Error getting teams count: $e');
      return 0;
    }
  }

  // Get events count for a specific user  
  Future<int> _getEventsCountForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('createdBy', isEqualTo: userId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting events count: $e');
      return 0;
    }
  }

  Future<void> _toggleFollow() async {
    if (_targetUserId == null) return;
    
    try {
      if (_isFollowing) {
        await _friendService.unfollowUser(_targetUserId!);
      } else {
        await _friendService.followUser(_targetUserId!, widget.username);
      }
      
      setState(() {
        _isFollowing = !_isFollowing;
        // Update followers count immediately for better UX
        _followersCount += _isFollowing ? 1 : -1;
      });
      
      // Reload actual data from Firebase to ensure accuracy
      _reloadFollowCounts();
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Reload follow counts from Firebase
  Future<void> _reloadFollowCounts() async {
    if (_targetUserId == null) return;
    
    try {
      Map<String, int> followCounts = await _getFollowCountsForUser(_targetUserId!);
      setState(() {
        _followingCount = followCounts['following'] ?? 0;
        _followersCount = followCounts['followers'] ?? 0;
      });
    } catch (e) {
      print('Error reloading follow counts: $e');
    }
  }

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
        title: Text(
          widget.username,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Show options menu
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                    child: const Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Posts', '$_postsCount'),
                      _buildStatColumn('Following', '$_followingCount'),
                      _buildStatColumn('Followers', '$_followersCount'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Follow Button
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing 
                            ? Colors.grey[300] 
                            : Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: _isFollowing 
                              ? Colors.black 
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Menu Items Section (like my profile page)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
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
                    icon: Icons.bar_chart,
                    title: 'Statistics',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Statistics coming soon!')),
                      );
                    },
                  ),
                  _buildMenuItemWithCount(
                    icon: Icons.article,
                    title: 'Posts',
                    count: _postsCount,
                    onTap: () {
                      if (_targetUserId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPostsPage(
                              username: widget.username,
                              userId: _targetUserId!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Teams and Events Section with counts
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
                        _buildSectionHeaderWithCount('Teams', _teamsCount, () {
                          if (_targetUserId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserTeamsPage(
                                  username: widget.username,
                                  userId: _targetUserId!,
                                ),
                              ),
                            );
                          }
                        }),
                        const SizedBox(height: 16),
                        _buildSectionHeaderWithCount('Events', _eventsCount, () {
                          if (_targetUserId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserEventsPage(
                                  username: widget.username,
                                  userId: _targetUserId!,
                                ),
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
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

  Widget _buildMenuItemWithCount({
    required IconData icon,
    required String title,
    required int count,
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
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionHeaderWithCount(String title, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User reported')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Profile'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile shared')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
