import 'package:flutter/material.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  // Current user profile data
  static const String _username = 'jindu yang';
  static const String _avatarInitial = 'j';
  static const Color _avatarColor = Color(0xFF2196F3); // Blue color

  String get username => _username;
  String get avatarInitial => _avatarInitial;
  Color get avatarColor => _avatarColor;

  // You can expand this later to load from preferences or API
  String? get avatarUrl => null; // For now, we'll use the initial
}
