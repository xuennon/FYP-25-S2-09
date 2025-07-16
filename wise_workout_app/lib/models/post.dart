class Post {
  final String id;
  final String username;
  final String postTime;
  final String content;
  final String? userAvatar;
  int likes;
  List<Comment> comments;
  bool isLikedByMe;

  Post({
    required this.id,
    required this.username,
    required this.postTime,
    required this.content,
    this.userAvatar,
    this.likes = 0,
    List<Comment>? comments,
    this.isLikedByMe = false,
  }) : comments = comments ?? [];
}

class Comment {
  final String id;
  final String username;
  final String text;
  final String timePosted;

  Comment({
    required this.id,
    required this.username,
    required this.text,
    required this.timePosted,
  });
}
