import 'package:flutter/material.dart';
import '../activity_details_page.dart';

class FirebaseActivity {
  final String id;
  final String userId;
  final String userName;
  final String userInitial;
  final String activityType;
  final DateTime date;
  final String distance;
  final String elevationGain;
  final String movingTime;
  final int durationSeconds;
  final double distanceKm;
  final String steps;
  final String calories;
  final String avgHeartRate;
  final double avgPace;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  FirebaseActivity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userInitial,
    required this.activityType,
    required this.date,
    required this.distance,
    required this.elevationGain,
    required this.movingTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.steps,
    required this.calories,
    required this.avgHeartRate,
    required this.avgPace,
    required this.createdAt,
    this.metadata,
  });

  // Convert to Firebase document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userInitial': userInitial,
      'activityType': activityType,
      'date': date.toIso8601String(),
      'distance': distance,
      'elevationGain': elevationGain,
      'movingTime': movingTime,
      'durationSeconds': durationSeconds,
      'distanceKm': distanceKm,
      'steps': steps,
      'calories': calories,
      'avgHeartRate': avgHeartRate,
      'avgPace': avgPace,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata ?? {},
    };
  }

  // Create from Firebase document
  factory FirebaseActivity.fromMap(Map<String, dynamic> data) {
    return FirebaseActivity(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userInitial: data['userInitial'] ?? '',
      activityType: data['activityType'] ?? '',
      date: DateTime.parse(data['date']),
      distance: data['distance'] ?? '',
      elevationGain: data['elevationGain'] ?? '',
      movingTime: data['movingTime'] ?? '',
      durationSeconds: data['durationSeconds'] ?? 0,
      distanceKm: (data['distanceKm'] ?? 0.0).toDouble(),
      steps: data['steps'] ?? '',
      calories: data['calories'] ?? '',
      avgHeartRate: data['avgHeartRate'] ?? '',
      avgPace: (data['avgPace'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(data['createdAt']),
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
    );
  }

  // Convert to ActivityDetail for UI compatibility
  ActivityDetail toActivityDetail() {
    return ActivityDetail(
      id: id,
      userName: userName,
      userInitial: userInitial,
      activityType: activityType,
      date: _formatDate(date),
      distance: distance,
      elevationGain: elevationGain,
      movingTime: movingTime,
      steps: steps,
      calories: calories,
      avgHeartRate: avgHeartRate,
      userColor: _getUserColor(userInitial),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${months[date.month]} ${date.day}, ${date.year} at $displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  // Helper method to get user color
  Color _getUserColor(String initial) {
    final colors = [
      const Color(0xFFFF6B35), // Orange
      const Color(0xFF4A90E2), // Blue
      const Color(0xFF50C878), // Green
      const Color(0xFF9B59B6), // Purple
      const Color(0xFFE74C3C), // Red
      const Color(0xFF1ABC9C), // Teal
      const Color(0xFF3498DB), // Light Blue
      const Color(0xFFE91E63), // Pink
    ];
    
    int index = initial.isNotEmpty ? initial.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}
