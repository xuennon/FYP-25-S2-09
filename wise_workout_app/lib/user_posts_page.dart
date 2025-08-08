import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/post.dart';
import 'individual_post_page.dart';

class UserPostsPage extends StatefulWidget {
  final String username;
  final String userId;
  
  const UserPostsPage({
    super.key, 
    required this.username,
    required this.userId,
  });

  @override
  State<UserPostsPage> createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Post> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get posts for this specific user
      QuerySnapshot querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .get();

      List<Post> posts = [];
      for (var doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Post post = await _convertFirebaseDataToPost(doc.id, data);
          posts.add(post);
        } catch (e) {
          print('Error converting post: $e');
        }
      }

      setState(() {
        _userPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Convert Firebase document data to Post model
  Future<Post> _convertFirebaseDataToPost(String docId, Map<String, dynamic> data) async {
    // Get timestamp and convert to readable format
    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    String postTime = _formatTimestamp(timestamp);

    // Get comments data
    List<Comment> comments = [];
    if (data['comments'] != null) {
      List<dynamic> commentsData = data['comments'] as List<dynamic>;
      comments = commentsData.map((commentData) => Comment(
        id: commentData['id'] ?? '',
        userId: commentData['userId'] ?? '',
        username: commentData['username'] ?? 'Unknown',
        text: commentData['comment'] ?? '',
        timePosted: _formatTimestamp(commentData['timestamp'] != null 
            ? commentData['timestamp'] as Timestamp 
            : null),
      )).toList();
    }

    return Post(
      id: docId,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Unknown User',
      postTime: postTime,
      content: data['content'] ?? '',
      userAvatar: null,
      likes: data['likes'] ?? 0,
      isLikedByMe: false, // Since we're viewing another user's posts
      comments: comments,
      images: List<String>.from(data['images'] ?? []),
    );
  }

  // Format timestamp to readable time
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    DateTime postDateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(postDateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${postDateTime.day}/${postDateTime.month}/${postDateTime.year}';
    }
  }

  Future<void> _refreshPosts() async {
    await _loadUserPosts();
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
          '${widget.username}\'s Posts',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : _userPosts.isEmpty
                ? Center(
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
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.username} hasn\'t posted anything yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _userPosts.length,
                    itemBuilder: (context, index) {
                      final post = _userPosts[index];
                      return _buildPostCard(post);
                    },
                  ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualPostPage(post: post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                    child: const Icon(Icons.person, size: 24, color: Colors.white),
                  ),
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
                ],
              ),
              const SizedBox(height: 12),
              
              // Post Content
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              
              // Post Images
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Post Stats
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likes}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.comments.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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
}
