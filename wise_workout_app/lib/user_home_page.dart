import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_page.dart';
import 'friend_list_page.dart';
import 'settings_page.dart';
import 'event_page.dart';
import 'my_profile_page.dart';
import 'models/post.dart';
import 'widgets/user_avatar.dart';
import 'write_post_page.dart';
import 'services/firebase_posts_service.dart';
import 'services/firebase_user_profile_service.dart';
import 'individual_post_page.dart';
import 'subscription_page.dart';
import 'workout_record_page.dart';
import 'main.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final FirebasePostsService _postsService = FirebasePostsService();
  final FirebaseUserProfileService _profileService = FirebaseUserProfileService();
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    // Check suspension status when the page loads
    _checkSuspensionStatus();
    
    // Listen to posts service changes
    _postsService.addListener(_onPostsChanged);
    // Load posts from Firebase after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
    
    // Add scroll listener to show/hide FAB
    _scrollController.addListener(_onScroll);
  }

  // Check if user is suspended and redirect to login if needed
  Future<void> _checkSuspensionStatus() async {
    try {
      bool isSuspended = await _profileService.isUserSuspended();
      if (isSuspended) {
        // Sign out the user and redirect to login
        await FirebaseAuth.instance.signOut();
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been suspended. Please contact support.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking suspension status: $e');
    }
  }

  @override
  void dispose() {
    _postsService.removeListener(_onPostsChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // Scrolling down - hide FAB
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      // Scrolling up - show FAB
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  void _onPostsChanged() {
    setState(() {
      // This will trigger a rebuild when posts change
    });
  }

  Future<void> _loadPosts() async {
    print('🏠 HomePage: Loading posts...');
    await _postsService.loadFeedPosts();
    print('🏠 HomePage: Posts loaded, count: ${_postsService.posts.length}');
  }

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
                onTap: () async {
                  print('🏠 HomePage: Navigating to MyProfilePage...');
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyProfilePage()),
                  );
                  
                  print('🏠 HomePage: Returned from MyProfilePage with result: $result');
                  
                  // If profile was updated, the username sync already refreshed posts
                  if (result == true) {
                    print('🏠 HomePage: Profile updated successfully, posts should already be synced');
                    // No need to call _loadPosts() again as syncUsernameAcrossPosts() handles it
                  } else {
                    print('🏠 HomePage: Profile update cancelled or no changes made');
                  }
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionPage()),
              );
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IndividualPostPage(post: post),
          ),
        );
      },
      child: Card(
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
            
            // Post images
            if (post.images.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildImageGrid(post.images),
              ),
            ],
            
            // Divider
            Divider(color: Colors.grey[300]),
            
            // Like, comment and share buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Like button
                InkWell(
                  onTap: () {
                    _postsService.toggleLike(post.id);
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
      ),
    ); // Closing the GestureDetector
  }

  Widget _buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();
    
    if (images.length == 1) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                size: 60,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                images[0],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 150,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 40, color: Colors.grey[600]),
                    const SizedBox(height: 4),
                    Text(
                      images[0],
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 150,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 40, color: Colors.grey[600]),
                    const SizedBox(height: 4),
                    Text(
                      images[1],
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // For 3 or more images, show a grid
      return Column(
        children: [
          if (images.length >= 3)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.only(right: 2, bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 30, color: Colors.grey[600]),
                          Text(
                            images[0],
                            style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.only(left: 2, bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 30, color: Colors.grey[600]),
                          Text(
                            images[1],
                            style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  margin: EdgeInsets.only(
                    right: images.length > 3 ? 2 : 0,
                    top: images.length >= 3 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 30, color: Colors.grey[600]),
                        Text(
                          images[images.length >= 3 ? 2 : 0],
                          style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (images.length > 3)
                Expanded(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Center(
                      child: Text(
                        '+${images.length - 3}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }
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
                          _postsService.addComment(post.id, commentController.text);
                          commentController.clear();
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
    if (_postsService.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_postsService.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow some users to see their posts here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _postsService.posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_postsService.posts[index]);
        },
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
          GestureDetector(
            onTap: () async {
              print('🏠 HomePage: Navigating to MyProfilePage from bottom nav...');
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyProfilePage()),
              );
              
              print('🏠 HomePage: Returned from MyProfilePage with result: $result');
              
              // If profile was updated, the username sync already refreshed posts
              if (result == true) {
                print('🏠 HomePage: Profile updated successfully, posts should already be synced');
                // No need to call _loadPosts() again as syncUsernameAcrossPosts() handles it
              } else {
                print('🏠 HomePage: Profile update cancelled or no changes made');
              }
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
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 80), // Add margin to lift it above bottom nav
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WritePostPage()),
                );
                
                // If a post was created, refresh the posts
                if (result == true) {
                  await _loadPosts();
                }
              },
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              elevation: 6,
              child: const Icon(
                Icons.add,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
