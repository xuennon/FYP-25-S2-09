import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final double? fontSize;
  final VoidCallback? onTap;
  
  const UserAvatar({
    super.key,
    this.radius = 20,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userProfile = UserProfileService();
    
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: userProfile.avatarColor,
      child: userProfile.avatarUrl != null 
        ? ClipOval(
            child: Image.network(
              userProfile.avatarUrl!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to initial if image fails to load
                return _buildInitialAvatar(userProfile);
              },
            ),
          )
        : _buildInitialAvatar(userProfile),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    
    return avatar;
  }

  Widget _buildInitialAvatar(UserProfileService userProfile) {
    return Text(
      userProfile.avatarInitial,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize ?? radius * 0.8,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
