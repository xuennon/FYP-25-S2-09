import 'package:flutter/material.dart';
import 'search_page.dart';
import 'friend_list_page.dart';
import 'settings_page.dart';
import 'event_page.dart';
import 'my_profile_page.dart';
import 'models/post.dart';
import 'widgets/user_avatar.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  // List of posts with their data
  List<Post> posts = [
    Post(
      id: '1',
      username: 'jindu yang',
      postTime: '21 seconds ago',
      content: 'Hello!',
      userAvatar: 'current_user', // Special marker for current user
    ),
    Post(
      id: '2',
      username: 'John Doe',
      postTime: '10 minutes ago',
      content: 'Just finished my workout! 💪 Feeling great after a 5k run and some strength training.',
      userAvatar: null,
      likes: 12,
      comments: [
        Comment(id: '1', username: 'Sarah', text: 'Great job!', timePosted: '5 minutes ago'),
        Comment(id: '2', username: 'Mike', text: 'What\'s your routine?', timePosted: '8 minutes ago'),
        Comment(id: '3', username: 'Jane', text: 'Keep it up!', timePosted: '9 minutes ago'),
      ],
    ),
    Post(
      id: '3',
      username: 'Sarah Smith',
      postTime: '45 minutes ago',
      content: 'Looking for a workout partner in the downtown area for morning runs! Anyone interested?',
      userAvatar: null,
      likes: 7,
      comments: [
        Comment(id: '1', username: 'Alex', text: 'I\'d be interested!', timePosted: '30 minutes ago'),
        Comment(id: '2', username: 'Emma', text: 'What time do you usually run?', timePosted: '35 minutes ago'),
        Comment(id: '3', username: 'Tom', text: 'I live downtown too, let\'s connect.', timePosted: '37 minutes ago'),
        Comment(id: '4', username: 'Lisa', text: 'I\'m a beginner, is that okay?', timePosted: '40 minutes ago'),
        Comment(id: '5', username: 'David', text: 'Count me in!', timePosted: '43 minutes ago'),
      ],
    ),
  ];
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Close dialog and navigate to login page
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Profile and Search
          Row(
            children: [
              UserAvatar(
                radius: 20,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyProfilePage()),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
              ),
            ],
          ),
          // Center - Upgrade Button
          ElevatedButton(
            onPressed: () {
              // TODO: Implement upgrade functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Right side - Settings and Logout
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: _handleLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                // User avatar
                post.userAvatar == 'current_user' 
                  ? UserAvatar(
                      radius: 20,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyProfilePage()),
                        );
                      },
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        image: post.userAvatar != null && post.userAvatar != 'current_user'
                            ? DecorationImage(
                                image: NetworkImage(post.userAvatar!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: post.userAvatar == null || post.userAvatar == 'current_user'
                          ? Center(
                              child: Text(
                                post.username.isNotEmpty ? post.username[0].toLowerCase() : 'u',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                const SizedBox(width: 12),
                // Username and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      post.postTime,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Post content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                post.content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            
            // Divider
            Divider(color: Colors.grey[300]),
            
            // Like, comment and share buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Like button
                InkWell(
                  onTap: () {
                    setState(() {
                      if (post.isLikedByMe) {
                        post.likes--;
                        post.isLikedByMe = false;
                      } else {
                        post.likes++;
                        post.isLikedByMe = true;
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          post.isLikedByMe ? Icons.thumb_up : Icons.thumb_up_outlined, 
                          size: 22, 
                          color: post.isLikedByMe ? Colors.blue : Colors.grey[800]
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.likes > 0 ? '${post.likes}' : '',
                          style: TextStyle(
                            color: post.isLikedByMe ? Colors.blue : Colors.grey[800]
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Comment button
                InkWell(
                  onTap: () {
                    _showCommentsDialog(post);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 22, color: Colors.grey[800]),
                        const SizedBox(width: 4),
                        Text(
                          post.comments.isNotEmpty ? '${post.comments.length}' : '',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Share button
                InkWell(
                  onTap: () {
                    _sharePost(post);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: Icon(Icons.share, size: 22, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _sharePost(Post post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Copy to Clipboard option
                    _buildShareOption(
                      icon: Icons.copy, 
                      label: 'Copy to\nClipboard', 
                      backgroundColor: const Color(0xFFF2F2F0),
                      onTap: () {
                        // Generate a mock link for the post
                        String postLink = 'https://wiseworkout.com/posts/${post.id}';
                        
                        // Copy to clipboard
                        // In a real app, you would use package:flutter/services.dart to access the clipboard
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Link copied to clipboard: $postLink')),
                        );
                      }
                    ),
                    
                    // Share To option
                    _buildShareOption(
                      icon: Icons.share, 
                      label: 'Share\nTo', 
                      backgroundColor: const Color(0xFFF2F2F0),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showSocialShareDialog(post);
                      }
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSocialShareDialog(Post post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share via',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildSocialMediaButton(
                      icon: 'X',
                      label: 'Post',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shared to X (Twitter)')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: null,
                      iconData: Icons.facebook,
                      label: 'Facebook',
                      backgroundColor: const Color(0xFF1877F2),
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shared to Facebook')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: null,
                      iconData: Icons.chat_bubble,
                      label: 'WhatsApp',
                      backgroundColor: const Color(0xFF25D366),
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shared to WhatsApp')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: 'Ig',
                      label: 'Instagram',
                      backgroundColor: Colors.purple,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shared to Instagram')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: null,
                      iconData: Icons.message,
                      label: 'Message',
                      backgroundColor: Colors.blue,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shared via Messages')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: null,
                      iconData: Icons.email,
                      label: 'Email',
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shared via Email')),
                        );
                      }
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSocialMediaButton({
    String? icon,
    IconData? iconData,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: icon != null
                ? Text(
                    icon,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Icon(
                    iconData,
                    color: textColor,
                    size: 36,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showCommentsDialog(Post post) {
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = post.comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const UserAvatar(radius: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        comment.timePosted,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment.text),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          setState(() {
                            post.comments.add(
                              Comment(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                username: 'You',
                                text: commentController.text,
                                timePosted: 'Just now',
                              ),
                            );
                            commentController.clear();
                          });
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(posts[index]);
      },
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home, color: Colors.grey[600], size: 28),
              const Text(
                'Home',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.grey[600], size: 28),
              const Text(
                'Post',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyProfilePage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, color: Colors.grey[600], size: 28),
                const Text(
                  'Profile',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                child: _buildPostsList(),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }
}
