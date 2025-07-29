import 'package:flutter/material.dart';
import 'discovered_team_details_page.dart';
import 'joined_teams_state.dart';
import 'services/firebase_friend_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final JoinedTeamsState _joinedTeamsState = JoinedTeamsState();
  final FirebaseFriendService _friendService = FirebaseFriendService();
  
  late TabController _tabController;
  List<Map<String, dynamic>> searchResults = []; // Changed to store user data from Firebase
  List<Map<String, String>> teamSearchResults = [];
  bool isSearching = false;

  // Mock user data for search
  final List<String> allUsers = [
    'john_doe',
    'sarah_smith', 
    'mike_wilson',
    'jane_parker',
    'alex_chen',
    'emma_davis',
    'tom_brown',
    'lisa_jones',
    'david_martin',
    'amy_taylor'
  ];

  // Mock team data for search
  final List<Map<String, String>> allTeams = [
    {'name': 'Fitness Warriors', 'description': 'Hardcore fitness team', 'members': '15'},
    {'name': 'Running Club', 'description': 'Daily morning runners', 'members': '8'},
    {'name': 'Gym Buddies', 'description': 'Weightlifting enthusiasts', 'members': '12'},
    {'name': 'Yoga Masters', 'description': 'Mindful movement group', 'members': '6'},
    {'name': 'CrossFit Champions', 'description': 'High intensity workouts', 'members': '20'},
    {'name': 'Cycling Squad', 'description': 'Weekend cycling adventures', 'members': '9'},
    {'name': 'Basketball Team', 'description': 'Local basketball players', 'members': '10'},
    {'name': 'Swimming Club', 'description': 'Pool training sessions', 'members': '7'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _performSearch(String query) async {
    setState(() {
      isSearching = true;
    });

    try {
      if (query.isEmpty) {
        setState(() {
          searchResults = [];
          teamSearchResults = [];
          isSearching = false;
        });
        return;
      }

      // Search users in Firebase
      List<Map<String, dynamic>> users = await _friendService.searchUsers(query);
      
      // Search teams (keeping existing logic for now)
      List<Map<String, String>> teams = allTeams
          .where((team) => 
              team['name']!.toLowerCase().contains(query.toLowerCase()) ||
              team['description']!.toLowerCase().contains(query.toLowerCase()))
          .toList();

      setState(() {
        searchResults = users;
        teamSearchResults = teams;
        isSearching = false;
      });
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        searchResults = [];
        teamSearchResults = [];
        isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Teams'),
          ],
          onTap: (index) {
            // Clear search when switching tabs
            _searchController.clear();
            setState(() {
              searchResults = [];
              teamSearchResults = [];
            });
          },
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _tabController.index == 0 ? 'Search Friends' : 'Find a team',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: _performSearch,
              ),
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildTeamsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Search for users to connect with',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found for "${_searchController.text}"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final userData = searchResults[index];
        final username = userData['username'] ?? 'Unknown User';
        final userId = userData['userId'] ?? userData['uid'] ?? ''; // Try userId first, then uid
        
        // Debug: Print user data structure
        print('User data for $username: $userData');
        print('Available keys: ${userData.keys}');
        print('User ID (userId): ${userData['userId']}');
        print('User ID (uid): ${userData['uid']}');
        print('Final userId: $userId');
        
        return FutureBuilder<bool>(
          future: _friendService.isFollowing(userId),
          builder: (context, snapshot) {
            final isFollowing = snapshot.data ?? false;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(userData['email'] ?? 'Fitness enthusiast'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      // Debug: Check if user is authenticated
                      print('Attempting to follow user...');
                      print('Current user authenticated: ${_friendService.currentUserId != null}');
                      print('Target user ID: $userId');
                      print('Target username: $username');
                      
                      if (userId.isEmpty) {
                        print('Error: User ID is empty');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Invalid user data'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      bool success;
                      if (isFollowing) {
                        success = await _friendService.unfollowUser(userId);
                      } else {
                        success = await _friendService.followUser(userId, username);
                      }
                      
                      if (success) {
                        setState(() {}); // Refresh the UI
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFollowing 
                                    ? 'Unfollowed $username' 
                                    : 'Following $username',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to ${isFollowing ? 'unfollow' : 'follow'} $username',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error following/unfollowing user: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey : Colors.blue,
                    minimumSize: const Size(80, 32),
                  ),
                  child: Text(
                    isFollowing ? 'Unfollow' : 'Follow',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () {
                  // Navigate to user profile (placeholder for now)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$username profile coming soon!')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Search for teams to join',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (teamSearchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No teams found for "${_searchController.text}"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teamSearchResults.length,
      itemBuilder: (context, index) {
        final team = teamSearchResults[index];
        final teamName = team['name']!;
        final isJoined = _joinedTeamsState.isTeamJoined(teamName);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flag,
                color: Colors.orange,
                size: 30,
              ),
            ),
            title: Text(
              teamName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team['description']!),
                const SizedBox(height: 4),
                Text(
                  '${team['members']} members',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isJoined) {
                    _joinedTeamsState.leaveTeam(teamName);
                  } else {
                    _joinedTeamsState.joinTeam(team);
                  }
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isJoined ? 'Left $teamName' : 'Joined $teamName!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isJoined ? Colors.grey : Colors.orange,
                minimumSize: const Size(80, 32),
              ),
              child: Text(
                isJoined ? 'Joined' : 'Join',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () async {
              // Navigate to team details page
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiscoveredTeamDetailsPage(
                    teamData: team,
                    initialJoinedState: isJoined,
                  ),
                ),
              );
              
              // Update the joined state if it changed
              if (result != null && result is bool) {
                setState(() {
                  if (result) {
                    _joinedTeamsState.joinTeam(team);
                  } else {
                    _joinedTeamsState.leaveTeam(teamName);
                  }
                });
              }
            },
          ),
        );
      },
    );
  }
}
