import 'package:flutter/material.dart';
import 'firebase_user_profile_service.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseUserProfileService _firebaseService = FirebaseUserProfileService();

  // Current user profile data (cached)
  String _username = 'User';
  String _avatarInitial = 'U';
  final Color _avatarColor = const Color(0xFF2196F3); // Blue color
  bool _isLoaded = false;

  // Getters that return cached data or defaults
  String get username => _username;
  String get avatarInitial => _avatarInitial;
  Color get avatarColor => _avatarColor;
  String? get avatarUrl => null; // For now, we'll use the initial

  // Load profile data from Firebase
  Future<void> loadProfile() async {
    try {
      String firebaseUsername = await _firebaseService.getUsername();
      
      if (firebaseUsername.isNotEmpty) {
        _username = firebaseUsername;
        _avatarInitial = firebaseUsername.isNotEmpty 
            ? firebaseUsername[0].toUpperCase() 
            : 'U';
        _isLoaded = true;
      }
    } catch (e) {
      print('Error loading profile in UserProfileService: $e');
      // Keep default values if loading fails
    }
  }

  // Get username asynchronously (always fresh from Firebase)
  Future<String> getUsernameAsync() async {
    try {
      String firebaseUsername = await _firebaseService.getUsername();
      _username = firebaseUsername;
      _avatarInitial = firebaseUsername.isNotEmpty 
          ? firebaseUsername[0].toUpperCase() 
          : 'U';
      return firebaseUsername;
    } catch (e) {
      print('Error getting username: $e');
      return _username;
    }
  }

  // Get avatar initial asynchronously
  Future<String> getAvatarInitialAsync() async {
    String name = await getUsernameAsync();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // Force refresh of cached data
  Future<void> refreshProfile() async {
    _isLoaded = false;
    await loadProfile();
  }

  // Check if profile has been loaded
  bool get isLoaded => _isLoaded;
}
