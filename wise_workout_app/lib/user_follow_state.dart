import 'package:flutter/material.dart';

// This is a simple state management class to track followed users across the app
class UserFollowState extends ChangeNotifier {
  // Singleton pattern to ensure only one instance exists
  static final UserFollowState _instance = UserFollowState._internal();
  
  factory UserFollowState() {
    return _instance;
  }
  
  UserFollowState._internal();
  
  // Set to store usernames of followed users
  final Set<String> _followedUsers = {};
  
  // Get the list of followed usernames
  List<String> get followedUsers => _followedUsers.toList();
  
  // Check if a user is followed
  bool isFollowing(String username) {
    return _followedUsers.contains(username);
  }
  
  // Follow a user
  void followUser(String username) {
    _followedUsers.add(username);
    notifyListeners();
  }
  
  // Unfollow a user
  void unfollowUser(String username) {
    _followedUsers.remove(username);
    notifyListeners();
  }
  
  // Toggle follow status (returns the new status)
  bool toggleFollowStatus(String username) {
    if (isFollowing(username)) {
      unfollowUser(username);
      return false;
    } else {
      followUser(username);
      return true;
    }
  }
}
