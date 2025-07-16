import 'package:flutter/material.dart';
import 'user_follow_state.dart';

class UserProfilePage extends StatefulWidget {
  final String username;
  
  const UserProfilePage({
    super.key,
    required this.username,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final UserFollowState _userFollowState = UserFollowState();

  void _toggleFollow() {
    bool isFollowing = _userFollowState.isFollowing(widget.username);
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
              'You will no longer see activities from your friend.',
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
                  _userFollowState.unfollowUser(widget.username);
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
      _userFollowState.followUser(widget.username);
      setState(() {}); // Refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.username,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Header with profile picture and follow button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Profile picture
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(width: 16),
                // Username and follow button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _toggleFollow,
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            _userFollowState.isFollowing(widget.username) ? Colors.grey[200] : Colors.white,
                          ),
                          side: WidgetStateProperty.all(
                            BorderSide(
                              color: _userFollowState.isFollowing(widget.username) ? Colors.grey : Colors.orange,
                            ),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                        ),
                        child: Text(
                          _userFollowState.isFollowing(widget.username) ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: _userFollowState.isFollowing(widget.username) ? Colors.black : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),
          // Profile content (empty for now)
          Expanded(
            child: Center(
              child: Text(
                'No posts yet from ${widget.username}',
                style: TextStyle(
                  color: Colors.grey[600],
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
