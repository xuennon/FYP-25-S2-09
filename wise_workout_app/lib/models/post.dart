class Post {
  final String id;
  final String username;
  final String postTime;
  final String content;
  final String? userAvatar;
  int likes;
  bool isLikedByMe;
  final List<Comment> comments;
  final List<String> images;

  Post({
    required this.id,
    required this.username,
    required this.postTime,
    required this.content,
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
