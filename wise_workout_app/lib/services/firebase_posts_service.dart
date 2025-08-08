import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import 'firebase_friend_service.dart';
import 'dart:math' as math;

class FirebasePostsService extends ChangeNotifier {
  static final FirebasePostsService _instance = FirebasePostsService._internal();
  factory FirebasePostsService() => _instance;
  FirebasePostsService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFriendService _friendService = FirebaseFriendService();

  List<Post> _posts = [];
  bool _isLoading = false;

  List<Post> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get currentUserId => _auth.currentUser?.uid;

  // Load posts from followed users, current user, and business posts
  Future<void> loadFeedPosts() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (currentUserId == null) {
        print('❌ No user authenticated');
        _posts = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('🔄 Loading feed posts for user: $currentUserId');

      // Get list of users being followed
      print('📋 Getting following list...');
      List<Map<String, dynamic>> followingList = await _friendService.getFollowing();
      print('📋 Following list result: $followingList');
      List<String> followingUserIds = followingList.map((user) => user['userId'].toString()).toList();
      
      // Add current user to see their own posts
      followingUserIds.add(currentUserId!);

      print('📋 Loading posts from ${followingUserIds.length} users: $followingUserIds');

      // Also check if there are any posts in the collection at all
      QuerySnapshot allPostsSnapshot = await _firestore
          .collection('posts')
          .limit(5)
          .get();
      print('📊 Total posts in collection: ${allPostsSnapshot.docs.length}');
      for (var doc in allPostsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('📄 Post sample: userId=${data['userId']}, content=${data['content']?.toString().substring(0, math.min(50, data['content']?.toString().length ?? 0))}...');
      }

      // Load regular user posts and business posts in parallel
      List<Post> loadedPosts = [];

      // Load regular user posts
      List<Post> userPosts = await _loadUserPosts(followingUserIds);
      loadedPosts.addAll(userPosts);

      // Load business posts
      List<Post> businessPosts = await _loadBusinessPosts();
      loadedPosts.addAll(businessPosts);

      // Posts are already sorted by timestamp from Firebase queries (descending order)
      // No need to re-sort here as both collections are ordered by timestamp

      _posts = loadedPosts;
      _isLoading = false;
      notifyListeners();

      print('🎯 Successfully loaded ${_posts.length} total posts to feed (${userPosts.length} user posts + ${businessPosts.length} business posts)');
    } catch (e) {
      print('❌ Error loading feed posts: $e');
      print('📋 Error details: ${e.toString()}');
      _posts = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load regular user posts
  Future<List<Post>> _loadUserPosts(List<String> followingUserIds) async {
    List<Post> userPosts = [];

    try {
      if (followingUserIds.length == 1) {
        // Only current user, query just their posts
        print('📊 Querying posts for current user only: $currentUserId');
        QuerySnapshot querySnapshot = await _firestore
            .collection('posts')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .limit(25)
            .get();

        print('📊 Found ${querySnapshot.docs.length} posts from current user');

        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            Post post = await _convertFirebaseDataToPost(doc.id, data);
            userPosts.add(post);
            print('✅ Loaded current user post: ${post.content.substring(0, math.min(30, post.content.length))}...');
          } catch (e) {
            print('❌ Error converting current user post ${doc.id}: $e');
          }
        }
      } else {
        // Query posts from followed users and current user
        print('📊 Querying posts from ${followingUserIds.length} users: $followingUserIds');
        QuerySnapshot querySnapshot = await _firestore
            .collection('posts')
            .where('userId', whereIn: followingUserIds)
            .orderBy('timestamp', descending: true)
            .limit(25)
            .get();

        print('📊 Found ${querySnapshot.docs.length} posts from all followed users');

        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            Post post = await _convertFirebaseDataToPost(doc.id, data);
            userPosts.add(post);
            print('✅ Loaded post from ${post.username}: ${post.content.substring(0, math.min(30, post.content.length))}...');
          } catch (e) {
            print('❌ Error converting post ${doc.id}: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error loading user posts: $e');
    }

    return userPosts;
  }

  // Load business posts
  Future<List<Post>> _loadBusinessPosts() async {
    List<Post> businessPosts = [];

    try {
      print('📊 Querying business posts...');
      QuerySnapshot querySnapshot = await _firestore
          .collection('businesspost')
          .orderBy('timestamp', descending: true)
          .limit(25)
          .get();

      print('📊 Found ${querySnapshot.docs.length} business posts');

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Post post = await _convertBusinessPostToPost(doc.id, data);
          businessPosts.add(post);
          print('✅ Loaded business post from ${post.username}: ${post.content.substring(0, math.min(30, post.content.length))}...');
        } catch (e) {
          print('❌ Error converting business post ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('❌ Error loading business posts: $e');
    }

    return businessPosts;
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

    // Check if current user liked this post
    bool isLiked = false;
    if (currentUserId != null && data['likedBy'] != null) {
      List<dynamic> likedBy = data['likedBy'] as List<dynamic>;
      isLiked = likedBy.contains(currentUserId);
    }

    List<String> images = List<String>.from(data['images'] ?? []);
    _debugLogPostImages(docId, images, 'Regular Post');

    return Post(
      id: docId,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Unknown User',
      postTime: postTime,
      content: data['content'] ?? '',
      title: null, // Regular posts don't have titles
      userAvatar: data['userId'] == currentUserId ? 'current_user' : null,
      likes: data['likes'] ?? 0,
      isLikedByMe: isLiked,
      comments: comments,
      images: images,
    );
  }

  void _debugLogPostImages(String postId, List<String> images, String postType) {
    print('🖼️ Post $postId ($postType) has ${images.length} images:');
    for (int i = 0; i < images.length; i++) {
      String img = images[i];
      print('  Image $i: ${img.length > 100 ? img.substring(0, 100) + "..." : img}');
      if (img.startsWith('http')) {
        print('    Type: Network URL');
      } else if (img.startsWith('data:image/') || img.contains('base64')) {
        print('    Type: Base64');
      } else if (img.startsWith('/') || img.contains('storage') || img.contains('cache')) {
        print('    Type: Local file');
      } else {
        print('    Type: Unknown');
      }
    }
  }

  // Convert business post Firebase document data to Post model
  Future<Post> _convertBusinessPostToPost(String docId, Map<String, dynamic> data) async {
    // Get timestamp and convert to readable format
    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    String postTime = _formatTimestamp(timestamp);

    // Business posts might have different structure, adapt as needed
    // Comments are handled separately for business posts
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

    // Business posts can be liked by users
    bool isLiked = false;
    if (currentUserId != null && data['likedBy'] != null) {
      List<dynamic> likedBy = data['likedBy'] as List<dynamic>;
      isLiked = likedBy.contains(currentUserId);
    }

    // Business posts might have different field names, adapt accordingly
    String businessName = data['userName'] ?? data['username'] ?? data['businessName'] ?? 'Business User';
    String content = data['description'] ?? data['content'] ?? '';
    String? title = data['title']; // Extract title from business post
    
    // Handle image URL - business posts might store images differently
    List<String> images = [];
    if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      images.add(data['imageUrl']);
    } else if (data['images'] != null) {
      images = List<String>.from(data['images']);
    }

    _debugLogPostImages(docId, images, 'Business Post');

    return Post(
      id: docId,
      userId: data['userId'] ?? 'business_user',
      username: businessName,
      postTime: postTime,
      content: content,
      title: title, // Include title for business posts
      userAvatar: 'business_user', // Special identifier for business posts
      likes: data['likes'] ?? 0,
      isLikedByMe: isLiked,
      comments: comments,
      images: images,
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

  // Create a new post
  Future<bool> createPost({
    required String content,
    List<String>? images,
  }) async {
    try {
      if (currentUserId == null) {
        print('❌ Error: User not authenticated');
        return false;
      }

      if (content.trim().isEmpty && (images == null || images.isEmpty)) {
        print('❌ Error: Post must have either content or images');
        return false;
      }

      // Get current user's username
      String username = await _getCurrentUsername();
      
      print('📝 Creating new post for user: $username ($currentUserId)');
      print('📄 Post content: ${content.substring(0, math.min(50, content.length))}...');

      // Create post data
      Map<String, dynamic> postData = {
        'userId': currentUserId,
        'username': username,
        'content': content.trim(),
        'images': images ?? [],
        'likes': 0,
        'likedBy': [],
        'comments': [],
        'timestamp': FieldValue.serverTimestamp(),
      };

      print('🔥 Sending post data to Firebase...');

      // Add to Firebase
      DocumentReference docRef = await _firestore.collection('posts').add(postData);
      
      print('✅ Post created successfully with ID: ${docRef.id}');

      // Wait a moment for Firebase to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload feed to show new post
      print('🔄 Reloading feed to show new post...');
      await loadFeedPosts();
      
      return true;
    } catch (e) {
      print('❌ Error creating post: $e');
      print('📋 Error details: ${e.toString()}');
      return false;
    }
  }

  // Like/unlike a post (handles both regular posts and business posts)
  Future<void> toggleLike(String postId) async {
    try {
      if (currentUserId == null) return;

      // Find the post to determine its type
      Post? post = _posts.where((p) => p.id == postId).firstOrNull;
      if (post == null) return;

      // Determine collection based on post type
      String collection = post.userAvatar == 'business_user' ? 'businesspost' : 'posts';
      DocumentReference postRef = _firestore.collection(collection).doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) return;
        
        Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;
        List<dynamic> likedBy = List.from(data['likedBy'] ?? []);
        int likes = data['likes'] ?? 0;
        
        if (likedBy.contains(currentUserId)) {
          // Unlike
          likedBy.remove(currentUserId);
          likes = likes > 0 ? likes - 1 : 0;
        } else {
          // Like
          likedBy.add(currentUserId);
          likes++;
        }
        
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': likes,
        });
      });

      // Update local post
      if (post.isLikedByMe) {
        post.likes--;
        post.isLikedByMe = false;
      } else {
        post.likes++;
        post.isLikedByMe = true;
      }
      notifyListeners();

      print('👍 Toggled like for $collection post: $postId');
    } catch (e) {
      print('❌ Error toggling like: $e');
    }
  }

  // Add comment to a post (handles both regular posts and business posts)
  Future<bool> addComment(String postId, String commentText) async {
    try {
      if (currentUserId == null) return false;

      // Find the post to determine its type
      Post? post = _posts.where((p) => p.id == postId).firstOrNull;
      if (post == null) return false;

      String username = await _getCurrentUsername();
      DateTime now = DateTime.now();
      
      Map<String, dynamic> commentData = {
        'id': now.millisecondsSinceEpoch.toString(),
        'userId': currentUserId,
        'username': username,
        'comment': commentText,
        'timestamp': Timestamp.fromDate(now), // Use Timestamp instead of serverTimestamp for arrayUnion
      };

      print('💬 Adding comment to post: $postId by user: $username');

      // Determine collection based on post type
      String collection = post.userAvatar == 'business_user' ? 'businesspost' : 'posts';

      // Add comment to Firebase
      await _firestore.collection(collection).doc(postId).update({
        'comments': FieldValue.arrayUnion([commentData]),
      });

      // Add comment to local post
      Comment newComment = Comment(
        id: commentData['id'],
        userId: currentUserId!,
        username: username,
        text: commentText,
        timePosted: 'Just now',
      );
      post.comments.add(newComment);
      notifyListeners();

      print('✅ Comment added successfully to $collection post: $postId');
      return true;
    } catch (e) {
      print('❌ Error adding comment: $e');
      return false;
    }
  }

  // Get current user's username
  Future<String> _getCurrentUsername() async {
    try {
      if (currentUserId == null) return 'User';

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['username'] ?? 'User';
      }
      return 'User';
    } catch (e) {
      print('❌ Error getting username: $e');
      return 'User';
    }
  }

  // Delete a post (only the creator can delete)
  Future<bool> deletePost(String postId) async {
    try {
      if (currentUserId == null) return false;

      // Find the post to determine its type
      Post? post = _posts.where((p) => p.id == postId).firstOrNull;
      if (post == null) {
        print('❌ Post not found in local cache');
        return false;
      }

      // Determine collection based on post type
      String collection = post.userAvatar == 'business_user' ? 'businesspost' : 'posts';

      // Check if current user is the creator
      DocumentSnapshot postDoc = await _firestore.collection(collection).doc(postId).get();
      if (!postDoc.exists) {
        print('❌ Post not found in $collection collection');
        return false;
      }

      Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUserId) {
        print('❌ User not authorized to delete this post');
        return false;
      }

      // Delete from Firebase
      await _firestore.collection(collection).doc(postId).delete();

      // Remove from local list
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();

      print('🗑️ Post deleted from $collection: $postId');
      return true;
    } catch (e) {
      print('❌ Error deleting post: $e');
      return false;
    }
  }

  // Update username across all user's posts and comments
  Future<bool> syncUsernameAcrossPosts(String newUsername) async {
    try {
      if (currentUserId == null) {
        print('❌ No current user to sync username for');
        return false;
      }

      print('🔄 Syncing username to "$newUsername" for user: $currentUserId');

      // Update all posts by this user
      QuerySnapshot userPosts = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: currentUserId)
          .get();

      int postsUpdated = 0;
      int commentsUpdated = 0;

      // Batch write for better performance
      WriteBatch batch = _firestore.batch();

      // Update usernames in posts
      for (QueryDocumentSnapshot postDoc in userPosts.docs) {
        batch.update(postDoc.reference, {'username': newUsername});
        postsUpdated++;

        // Also update username in comments made by this user within this post
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        List<dynamic> comments = postData['comments'] ?? [];
        
        bool commentsNeedUpdate = false;
        for (int i = 0; i < comments.length; i++) {
          if (comments[i]['userId'] == currentUserId) {
            comments[i]['username'] = newUsername;
            commentsNeedUpdate = true;
            commentsUpdated++;
          }
        }
        
        if (commentsNeedUpdate) {
          batch.update(postDoc.reference, {'comments': comments});
        }
      }

      // Now update comments in other users' posts
      QuerySnapshot allPosts = await _firestore.collection('posts').get();
      
      for (QueryDocumentSnapshot postDoc in allPosts.docs) {
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        
        // Skip posts we already processed above
        if (postData['userId'] == currentUserId) continue;
        
        List<dynamic> comments = postData['comments'] ?? [];
        bool commentsNeedUpdate = false;
        
        for (int i = 0; i < comments.length; i++) {
          if (comments[i]['userId'] == currentUserId) {
            comments[i]['username'] = newUsername;
            commentsNeedUpdate = true;
            commentsUpdated++;
          }
        }
        
        if (commentsNeedUpdate) {
          batch.update(postDoc.reference, {'comments': comments});
        }
      }

      // Commit all updates
      await batch.commit();
      print('✅ Firebase batch commit completed');

      // Add a small delay to ensure Firebase propagation
      await Future.delayed(const Duration(milliseconds: 500));

      // Update local posts cache
      for (Post post in _posts) {
        if (post.userId == currentUserId) {
          post.username = newUsername;
        }
        // Update comments in local cache
        for (Comment comment in post.comments) {
          if (comment.userId == currentUserId) {
            comment.username = newUsername;
          }
        }
      }

      // Notify listeners immediately with local changes
      notifyListeners();

      // Also reload from Firebase to ensure consistency
      print('🔄 Reloading posts from Firebase to ensure sync...');
      await loadFeedPosts();

      print('✅ Username sync completed: $postsUpdated posts and $commentsUpdated comments updated');
      return true;
    } catch (e) {
      print('❌ Error syncing username across posts: $e');
      return false;
    }
  }

  // Delete a comment from a post (handles both regular posts and business posts)
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      // Find the post to determine its type
      Post? post = _posts.where((p) => p.id == postId).firstOrNull;
      if (post == null) {
        print('❌ Post not found in local cache');
        return false;
      }

      print('🗑️ Deleting comment $commentId from post $postId');

      // Determine collection based on post type
      String collection = post.userAvatar == 'business_user' ? 'businesspost' : 'posts';

      // Get the post document reference
      DocumentReference postRef = _firestore.collection(collection).doc(postId);
      DocumentSnapshot postDoc = await postRef.get();

      if (!postDoc.exists) {
        print('❌ Post not found in $collection collection');
        return false;
      }

      // Get current comments
      Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
      List<dynamic> comments = postData['comments'] ?? [];

      // Find the comment to remove and verify ownership
      dynamic commentToRemove;
      for (var comment in comments) {
        if (comment['id'] == commentId && comment['userId'] == currentUserId) {
          commentToRemove = comment;
          break;
        }
      }

      if (commentToRemove == null) {
        print('❌ Comment not found or user not authorized to delete');
        return false;
      }

      // Remove the comment
      comments.remove(commentToRemove);

      // Update the post document with the new comments array
      await postRef.update({
        'comments': comments,
      });

      // Update local posts list
      int postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex].comments.removeWhere((comment) => comment.id == commentId);
        notifyListeners();
      }

      print('✅ Comment deleted successfully from $collection post');
      return true;
    } catch (e) {
      print('❌ Error deleting comment: $e');
      return false;
    }
  }

  // Clear all local posts (useful for logout)
  void clearPosts() {
    _posts = [];
    notifyListeners();
  }
}
