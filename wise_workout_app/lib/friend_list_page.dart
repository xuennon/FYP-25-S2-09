import 'package:flutter/material.dart';
import 'user_profile_page.dart';
import 'services/firebase_friend_service.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFriendService _friendService = FirebaseFriendService();
  
  List<Map<String, dynamic>> _followingList = [];
  List<Map<String, dynamic>> _followersList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendsData();
  }

  Future<void> _loadFriendsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final following = await _friendService.getFollowing();
      final followers = await _friendService.getFollowers();
      
      setState(() {
        _followingList = following;
        _followersList = followers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friends data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
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
        title: const Text(
          'Following',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Following'),
            Tab(text: 'Followers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Following Tab
                _followingList.isEmpty 
                  ? const Center(child: Text('You are not following anyone yet'))
                  : ListView.builder(
                      itemCount: _followingList.length,
                      itemBuilder: (context, index) {
                        return _buildFollowedUserItem(_followingList[index]);
                      },
                    ),
                
                // Followers Tab
                _followersList.isEmpty 
                  ? const Center(child: Text('No followers yet'))
                  : ListView.builder(
                      itemCount: _followersList.length,
                      itemBuilder: (context, index) {
                        return _buildFollowerUserItem(_followersList[index]);
                      },
                    ),
              ],
            ),
    );
  }

  Widget _buildFollowedUserItem(Map<String, dynamic> userDoc) {
    final username = userDoc['username'] ?? 'Unknown User';
    final userId = userDoc['userId'] ?? '';
    
    return StatefulBuilder(
      builder: (context, setItemState) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
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
              // Username - makes the whole row tappable to go to profile
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(username: username),
                      ),
                    ).then((_) {
                      // Refresh UI when returning from profile page
                      _loadFriendsData();
                    });
                  },
                  child: Text(
                    username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Unfollow button
              OutlinedButton(
                onPressed: () {
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
                          'You will no longer see activities from your friend. If you favorited them or enabled notifications for their activities, those preferences will be disabled',
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
                            onPressed: () async {
                              try {
                                await _friendService.unfollowUser(userId);
                                // Refresh the friends list
                                _loadFriendsData();
                                Navigator.of(context).pop(); // Close dialog
                              } catch (e) {
                                print('Error unfollowing user: $e');
                                Navigator.of(context).pop(); // Close dialog
                              }
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
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.grey[200]),
                  side: WidgetStateProperty.all(
                    const BorderSide(color: Colors.grey),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
                child: const Text(
                  'Following',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowerUserItem(Map<String, dynamic> userDoc) {
    final username = userDoc['username'] ?? 'Unknown User';
    final userId = userDoc['userId'] ?? '';
    
    return StatefulBuilder(
      builder: (context, setItemState) {
        return FutureBuilder<bool>(
          future: _friendService.isFollowing(userId),
          builder: (context, snapshot) {
            final isFollowing = snapshot.data ?? false;
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
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
                  // Username - makes the whole row tappable to go to profile
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(username: username),
                          ),
                        ).then((_) {
                          // Refresh UI when returning from profile page
                          setItemState(() {});
                        });
                      },
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Follow/Following button
                  OutlinedButton(
                    onPressed: snapshot.connectionState == ConnectionState.waiting
                        ? null
                        : () async {
                            try {
                              if (isFollowing) {
                                await _friendService.unfollowUser(userId);
                              } else {
                                await _friendService.followUser(userId, username);
                              }
                              // Update the UI
                              setItemState(() {});
                              _loadFriendsData();
                            } catch (e) {
                              print('Error following/unfollowing user: $e');
                            }
                          },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        isFollowing ? Colors.grey[200] : Colors.white,
                      ),
                      side: WidgetStateProperty.all(
                        BorderSide(
                          color: isFollowing ? Colors.grey : Colors.orange,
                        ),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                    ),
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: isFollowing ? Colors.black : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
