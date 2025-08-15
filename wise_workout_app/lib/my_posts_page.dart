// Clean my_posts_page.dart - removing the corrupted _buildImageGrid method

import 'package:flutter/material.dart';
import 'models/post.dart';
import 'services/firebase_posts_service.dart';
import 'widgets/user_avatar.dart';
import 'widgets/post_image_widget.dart';
import 'individual_post_page.dart';
import 'edit_post_page.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final FirebasePostsService _postsService = FirebasePostsService();
  List<Post> _myPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
    _postsService.addListener(_onPostsChanged);
  }

  @override
  void dispose() {
    _postsService.removeListener(_onPostsChanged);
    super.dispose();
  }

  void _onPostsChanged() {
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    try {
      // Get current user ID
      String? currentUserId = _postsService.currentUserId;
      if (currentUserId == null) {
        setState(() {
          _myPosts = [];
          _isLoading = false;
        });
        return;
      }

      // Filter posts to show only current user's posts
      List<Post> allPosts = _postsService.posts;
      List<Post> userPosts = allPosts.where((post) => post.userId == currentUserId).toList();
      
      // Sort posts by most recent first
      userPosts.sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        _myPosts = userPosts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading my posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _isLoading = true;
    });
    await _postsService.loadFeedPosts();
    _loadMyPosts();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Posts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshPosts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myPosts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myPosts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_myPosts[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your first post to get started!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualPostPage(post: post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and time
              Row(
                children: [
                  const UserAvatar(radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
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
                  ),
                  // Three dots menu
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () {
                      _showPostOptions(post);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Post content
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              
              // Post images
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                PostImageGrid(images: post.images),
              ],
              
              const SizedBox(height: 12),
              
              // Stats row
              Row(
                children: [
                  Icon(
                    post.isLikedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 20,
                    color: post.isLikedByMe ? Colors.blue : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likes}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.comments.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Post'),
                onTap: () async {
                  Navigator.pop(context);
                  // Navigate to EditPostPage
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostPage(post: post),
                    ),
                  );
                  
                  // If post was updated, refresh the posts list
                  if (result == true) {
                    await _loadMyPosts();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(post);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Post post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _deletePost(post);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(Post post) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete the post using the posts service
      bool success = await _postsService.deletePost(post.id);
      
      // Hide loading indicator
      Navigator.pop(context);

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the posts list
        _loadMyPosts();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
