import 'package:flutter/material.dart';
import 'discovered_team_details_page.dart';
import 'user_profile_page.dart';
import 'services/firebase_friend_service.dart';
import 'services/firebase_teams_service.dart';
import 'models/team.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final FirebaseTeamsService _teamsService = FirebaseTeamsService();
  
  late TabController _tabController;
  List<Map<String, dynamic>> searchResults = []; // Store user data from Firebase
  bool isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Start listening for teams when the page loads
    _teamsService.startListening();
  }

  void _performSearch(String query) async {
    setState(() {
      isSearching = true;
      _searchQuery = query;
    });

    try {
      if (query.isEmpty) {
        setState(() {
          searchResults = [];
          isSearching = false;
          _searchQuery = '';
        });
        return;
      }

      // Search users in Firebase
      List<Map<String, dynamic>> users = await _friendService.searchUsers(query);
      
      setState(() {
        searchResults = users;
        isSearching = false;
      });
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        searchResults = [];
        isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _teamsService.stopListening();
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
              _searchQuery = '';
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
                  // Navigate to user profile page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(username: username),
                    ),
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
    return StreamBuilder<List<Team>>(
      stream: _teamsService.getTeamsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading teams: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final allTeams = snapshot.data ?? [];
        final filteredTeams = allTeams.where((team) {
          if (_searchQuery.isEmpty) return true;
          return team.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 team.description.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (_searchQuery.isNotEmpty && filteredTeams.isEmpty) {
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
                  'No teams found for "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (_searchQuery.isEmpty) {
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTeams.length,
          itemBuilder: (context, index) {
            final team = filteredTeams[index];
            final isJoined = _teamsService.isTeamMember(team.id);
            
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
                  team.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.description),
                    const SizedBox(height: 4),
                    Text(
                      '${team.memberCount} members',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      bool success;
                      if (isJoined) {
                        success = await _teamsService.leaveTeam(team.id);
                      } else {
                        success = await _teamsService.joinTeam(team.id);
                      }
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isJoined ? 'Left ${team.name}' : 'Joined ${team.name}!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to ${isJoined ? 'leave' : 'join'} team'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
                  // Navigate to team details page using Map conversion
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiscoveredTeamDetailsPage(
                        teamData: {
                          'name': team.name,
                          'description': team.description,
                          'members': team.memberCount.toString(),
                          'creator': team.createdBy,
                          'createdAt': team.createdAt.toString(),
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
