class Post {
  final String id;
  final String userId; // Add userId field for identifying post owner
  String username; // Make username mutable for syncing
  final String postTime;
  final String content;
  final String? title; // Add title field for business posts
  final String? userAvatar;
  int likes;
  bool isLikedByMe;
  final List<Comment> comments;
  final List<String> images;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.postTime,
    required this.content,
    this.title,
    this.userAvatar,
    this.likes = 0,
    this.isLikedByMe = false,
    List<Comment>? comments,
    List<String>? images,
  }) : comments = comments ?? [],
       images = images ?? [];
}

class Comment {
  final String id;
  final String userId; // Add userId field for identifying comment owner
  String username; // Make username mutable for syncing
  final String text;
  final String timePosted;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.timePosted,
  });
}
