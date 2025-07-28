import 'package:flutter/foundation.dart';
import '../models/post.dart';

class PostsService extends ChangeNotifier {
  static final PostsService _instance = PostsService._internal();
  factory PostsService() => _instance;
  PostsService._internal() {
    _initializePosts();
  }

  List<Post> _posts = [];
  
  List<Post> get posts => List.unmodifiable(_posts);

  void _initializePosts() {
    _posts = [
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
        images: ['workout_pic_1', 'gym_selfie'],
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
        images: ['running_route', 'morning_view', 'running_shoes', 'park_pic'],
        comments: [
          Comment(id: '1', username: 'Alex', text: 'I\'d be interested!', timePosted: '30 minutes ago'),
          Comment(id: '2', username: 'Emma', text: 'What time do you usually run?', timePosted: '35 minutes ago'),
          Comment(id: '3', username: 'Tom', text: 'I live downtown too, let\'s connect.', timePosted: '37 minutes ago'),
          Comment(id: '4', username: 'Lisa', text: 'I\'m a beginner, is that okay?', timePosted: '40 minutes ago'),
          Comment(id: '5', username: 'David', text: 'Count me in!', timePosted: '43 minutes ago'),
        ],
      ),
    ];
  }

  void addPost(Post post) {
    _posts.insert(0, post); // Add new post at the beginning
    notifyListeners();
  }

  void addPostFromData(Map<String, dynamic> postData) {
    final post = Post(
      id: postData['id'],
      username: postData['username'],
      postTime: postData['postTime'],
      content: postData['content'],
      userAvatar: postData['userAvatar'],
      likes: postData['likes'],
      comments: (postData['comments'] as List<dynamic>)
          .map((c) => Comment(
            id: c['id'],
            username: c['username'],
            text: c['text'],
            timePosted: c['timePosted'],
          ))
          .toList(),
      images: List<String>.from(postData['images']),
      isLikedByMe: postData['isLikedByMe'],
    );
    addPost(post);
  }

  void updatePost(Post updatedPost) {
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }

  void deletePost(String postId) {
    _posts.removeWhere((post) => post.id == postId);
    notifyListeners();
  }

  Post? getPostById(String id) {
    try {
      return _posts.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }

  void likePost(String postId) {
    final post = getPostById(postId);
    if (post != null) {
      if (post.isLikedByMe) {
        post.likes--;
        post.isLikedByMe = false;
      } else {
        post.likes++;
        post.isLikedByMe = true;
      }
      notifyListeners();
    }
  }

  void addComment(String postId, Comment comment) {
    final post = getPostById(postId);
    if (post != null) {
      post.comments.add(comment);
      notifyListeners();
    }
  }
}
