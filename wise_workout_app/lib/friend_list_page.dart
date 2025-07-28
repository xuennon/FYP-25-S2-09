import 'package:flutter/material.dart';
import 'user_profile_page.dart';
import 'user_follow_state.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserFollowState _userFollowState = UserFollowState();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Following Tab
          Builder(
            builder: (context) {
              final followedUsers = _userFollowState.followedUsers;
              return followedUsers.isEmpty 
                ? const Center(child: Text('You are not following anyone yet'))
                : ListView.builder(
                    itemCount: followedUsers.length,
                    itemBuilder: (context, index) {
                      return _buildFollowedUserItem(followedUsers[index]);
                    },
                  );
            }
          ),
          
          // Followers Tab (placeholder for now)
          const Center(child: Text('No followers yet')),
        ],
      ),
    );
  }

  Widget _buildFollowedUserItem(String username) {
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
                      setState(() {});
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
                onPressed: () {
                  if (_userFollowState.isFollowing(username)) {
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
                              onPressed: () {
                                _userFollowState.unfollowUser(username);
                                // Update the UI
                                setItemState(() {});
                                setState(() {});
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
                    _userFollowState.followUser(username);
                    // Update the UI
                    setItemState(() {});
                    setState(() {});
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    _userFollowState.isFollowing(username) ? Colors.grey[200] : Colors.white,
                  ),
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: _userFollowState.isFollowing(username) ? Colors.grey : Colors.orange,
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
                child: Text(
                  _userFollowState.isFollowing(username) ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: _userFollowState.isFollowing(username) ? Colors.black : Colors.orange,
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
}
