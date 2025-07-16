import 'package:flutter/material.dart';
import 'user_profile_page.dart';
import 'user_follow_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;
  final UserFollowState _userFollowState = UserFollowState();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _performSearch(String query) {
    // This is a simplified version - in a real app, you would search a database
    if (query.toLowerCase().contains('user123')) {
      setState(() {
        _showSearchResults = true;
      });
    } else {
      setState(() {
        _showSearchResults = false;
      });
    }
  }

  void _toggleFollow(String username) {
    bool isFollowing = _userFollowState.isFollowing(username);
    if (isFollowing) {
      // Show confirmation dialog when unfollowing
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Are you sure?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'You will no longer see activities from your friend. ',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _userFollowState.unfollowUser(username);
                  setState(() {}); // Refresh UI
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text(
                  'Unfollow',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          );
        },
      );
    } else {
      // If not following, simply follow
      _userFollowState.followUser(username);
      setState(() {}); // Refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (value) => _performSearch(value),
              ),
            ),
          ),
          _showSearchResults
          ? Expanded(
              child: Column(
                children: [
                  // User profile header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => const UserProfilePage(username: 'User123')
                              )
                            );
                          },
                          child: Row(
                            children: [
                              // User avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                                child: const Icon(Icons.person, size: 40, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              // Username
                              const Text(
                                'User123',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Follow button
                        OutlinedButton(
                          onPressed: () => _toggleFollow('User123'),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              _userFollowState.isFollowing('User123') ? Colors.grey[200] : Colors.white,
                            ),
                            side: WidgetStateProperty.all(
                              BorderSide(
                                color: _userFollowState.isFollowing('User123') ? Colors.grey : Colors.orange,
                              ),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          child: Text(
                            _userFollowState.isFollowing('User123') ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: _userFollowState.isFollowing('User123') ? Colors.black : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // User profile content
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: const Center(
                        child: Text(
                          'No posts yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const Expanded(
              child: Center(
                child: Text(
                  'Search for workout buddies',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}