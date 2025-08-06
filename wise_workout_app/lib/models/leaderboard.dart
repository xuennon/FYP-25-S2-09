class LeaderboardEntry {
  final String userId;
  final String userName;
  final String userProfileImageUrl;
  final String userInitial;
  final Map<String, dynamic> metrics; // Stores activity metrics (time, distance, etc.)
  final DateTime recordedAt;
  final String activityId; // Reference to the activity that created this entry

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userProfileImageUrl = '',
    required this.userInitial,
    required this.metrics,
    required this.recordedAt,
    required this.activityId,
  });

  // Get formatted time based on the activity type
  String get formattedTime {
    if (metrics.containsKey('durationSeconds')) {
      int seconds = metrics['durationSeconds'] as int;
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      int remainingSeconds = seconds % 60;
      
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m ${remainingSeconds}s';
      }
    }
    return 'N/A';
  }

  // Get distance if available
  String get formattedDistance {
    if (metrics.containsKey('distanceKm')) {
      double distance = (metrics['distanceKm'] as num).toDouble();
      return '${distance.toStringAsFixed(2)} km';
    }
    return 'N/A';
  }

  // Get the main ranking metric based on event's primary metric
  double getRankingValue(String primaryMetric, bool isLowerBetter) {
    if (!metrics.containsKey(primaryMetric)) {
      // Return worst possible value if metric not found
      return isLowerBetter ? double.infinity : -double.infinity;
    }
    
    double value = (metrics[primaryMetric] as num).toDouble();
    
    // For "higher is better" metrics, return negative value for sorting
    // (since default sort is ascending)
    return isLowerBetter ? value : -value;
  }

  // Get formatted display value for the primary metric
  String getFormattedValue(String primaryMetric) {
    if (!metrics.containsKey(primaryMetric)) {
      return 'N/A';
    }

    double value = (metrics[primaryMetric] as num).toDouble();
    
    switch (primaryMetric) {
      case 'durationSeconds':
        int seconds = value.round();
        int hours = seconds ~/ 3600;
        int minutes = (seconds % 3600) ~/ 60;
        int remainingSeconds = seconds % 60;
        
        if (hours > 0) {
          return '${hours}h ${minutes}m ${remainingSeconds}s';
        } else if (minutes > 0) {
          return '${minutes}m ${remainingSeconds}s';
        } else {
          return '${remainingSeconds}s';
        }
        
      case 'distanceKm':
        return '${value.toStringAsFixed(2)} km';
        
      case 'elevation':
        return '${value.toStringAsFixed(0)} m';
        
      case 'avgPace':
        // Pace is usually in minutes per km
        int totalSeconds = (value * 60).round();
        int minutes = totalSeconds ~/ 60;
        int seconds = totalSeconds % 60;
        return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
        
      default:
        return value.toStringAsFixed(2);
    }
  }

  // Legacy method - kept for backward compatibility
  double get rankingValue {
    // Default behavior - rank by time if available, otherwise distance
    if (metrics.containsKey('durationSeconds')) {
      return (metrics['durationSeconds'] as num).toDouble();
    }
    
    if (metrics.containsKey('distanceKm')) {
      return -(metrics['distanceKm'] as num).toDouble(); // Negative to sort desc
    }
    
    return double.infinity; // Default to worst ranking
  }

  // Convert to Firebase document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'userInitial': userInitial,
      'metrics': metrics,
      'recordedAt': recordedAt.toIso8601String(),
      'activityId': activityId,
    };
  }

  // Create from Firebase document
  factory LeaderboardEntry.fromMap(Map<String, dynamic> data) {
    return LeaderboardEntry(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfileImageUrl: data['userProfileImageUrl'] ?? '',
      userInitial: data['userInitial'] ?? '',
      metrics: Map<String, dynamic>.from(data['metrics'] ?? {}),
      recordedAt: DateTime.parse(data['recordedAt']),
      activityId: data['activityId'] ?? '',
    );
  }
}

class EventLeaderboard {
  final String eventId;
  final List<LeaderboardEntry> entries;
  final DateTime lastUpdated;
  final String? primaryMetric;
  final bool? isLowerBetter;

  EventLeaderboard({
    required this.eventId,
    required this.entries,
    required this.lastUpdated,
    this.primaryMetric,
    this.isLowerBetter,
  });

  // Get top N entries (default 10) sorted by the event's primary metric
  List<LeaderboardEntry> getTopEntries([int limit = 10]) {
    if (entries.isEmpty) return [];
    
    // Use event's primary metric for sorting if available
    String metric = primaryMetric ?? 'durationSeconds';
    bool lowerIsBetter = isLowerBetter ?? true;
    
    List<LeaderboardEntry> sortedEntries = List.from(entries);
    
    // Sort by the primary metric value
    sortedEntries.sort((a, b) {
      double aValue = a.getRankingValue(metric, lowerIsBetter);
      double bValue = b.getRankingValue(metric, lowerIsBetter);
      return aValue.compareTo(bValue);
    });
    
    return sortedEntries.take(limit).toList();
  }

  // Get user's ranking (1-based) using event's primary metric
  int getUserRank(String userId) {
    if (entries.isEmpty) return -1;
    
    // Use event's primary metric for ranking if available
    String metric = primaryMetric ?? 'durationSeconds';
    bool lowerIsBetter = isLowerBetter ?? true;
    
    List<LeaderboardEntry> sortedEntries = List.from(entries);
    
    // Sort by the primary metric value
    sortedEntries.sort((a, b) {
      double aValue = a.getRankingValue(metric, lowerIsBetter);
      double bValue = b.getRankingValue(metric, lowerIsBetter);
      return aValue.compareTo(bValue);
    });
    
    for (int i = 0; i < sortedEntries.length; i++) {
      if (sortedEntries[i].userId == userId) {
        return i + 1;
      }
    }
    return -1; // User not found
  }

  // Convert to Firebase document
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'entries': entries.map((entry) => entry.toMap()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'primaryMetric': primaryMetric,
      'isLowerBetter': isLowerBetter,
    };
  }

  // Create from Firebase document
  factory EventLeaderboard.fromMap(Map<String, dynamic> data) {
    List<dynamic> entriesData = data['entries'] ?? [];
    List<LeaderboardEntry> entries = entriesData
        .map((entryData) => LeaderboardEntry.fromMap(entryData))
        .toList();

    return EventLeaderboard(
      eventId: data['eventId'] ?? '',
      entries: entries,
      lastUpdated: DateTime.parse(data['lastUpdated']),
      primaryMetric: data['primaryMetric'],
      isLowerBetter: data['isLowerBetter'],
    );
  }
}
