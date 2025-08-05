import 'package:flutter/material.dart';

class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  final List<WorkoutActivity> _activities = [];

  List<WorkoutActivity> get activities => List.unmodifiable(_activities);

  void addActivity(WorkoutActivity activity) {
    _activities.insert(0, activity); // Add to beginning (most recent first)
    notifyListeners();
  }

  void removeActivity(String activityId) {
    _activities.removeWhere((activity) => activity.id == activityId);
    notifyListeners();
  }

  void clearActivities() {
    _activities.clear();
    notifyListeners();
  }
}

class WorkoutActivity {
  final String id;
  final String sportType;
  final DateTime date;
  final int durationSeconds;
  final double distanceKm;
  final int steps;
  final int calories;
  final double avgPace; // min/km

  WorkoutActivity({
    required this.id,
    required this.sportType,
    required this.date,
    required this.durationSeconds,
    required this.distanceKm,
    required this.steps,
    required this.calories,
    required this.avgPace,
  });

  String get formattedDuration {
    int hours = durationSeconds ~/ 3600;
    int minutes = (durationSeconds % 3600) ~/ 60;
    int secs = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${secs}s';
    }
  }

  String get formattedDistance {
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  String get formattedCalories {
    return '$calories kcal';
  }

  String get formattedDate {
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

  String get activityTitle {
    final timeOfDay = date.hour;
    String timePrefix;
    
    if (timeOfDay < 12) {
      timePrefix = 'Morning';
    } else if (timeOfDay < 17) {
      timePrefix = 'Afternoon';
    } else {
      timePrefix = 'Evening';
    }
    
    return '$timePrefix $sportType';
  }

  IconData get sportIcon {
    switch (sportType) {
      case 'Walk':
        return Icons.directions_walk;
      case 'Run':
        return Icons.directions_run;
      case 'Cycling':
        return Icons.directions_bike;
      case 'Hiking':
        return Icons.terrain;
      case 'Swimming':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  Color get activityColor {
    switch (sportType) {
      case 'Walk':
        return Colors.green;
      case 'Run':
        return Colors.orange;
      case 'Cycling':
        return Colors.blue;
      case 'Hiking':
        return Colors.brown;
      case 'Swimming':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
