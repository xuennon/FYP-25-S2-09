import 'package:flutter/material.dart';
import '../models/leaderboard.dart';

class LeaderboardWidget extends StatelessWidget {
  final EventLeaderboard leaderboard;
  final String currentUserId;

  const LeaderboardWidget({
    super.key,
    required this.leaderboard,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    List<LeaderboardEntry> topEntries = leaderboard.getTopEntries(10);
    
    if (topEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.leaderboard,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No records yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete activities to see rankings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Leaderboard header with tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildTab('OVERALL', true),
                const SizedBox(width: 32),
                _buildTab('FOLLOWING', false),
              ],
            ),
          ),
          
          // Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 40, child: Text('RANK', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500))),
                const Expanded(child: Text('ATHLETE', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500))),
                Text(
                  _getMetricHeaderText(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          // Leaderboard entries
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topEntries.length,
            itemBuilder: (context, index) {
              LeaderboardEntry entry = topEntries[index];
              bool isCurrentUser = entry.userId == currentUserId;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.orange.withOpacity(0.1) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser ? Colors.orange : Colors.black,
                        ),
                      ),
                    ),
                    
                    // Profile picture
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getProfileColor(entry.userInitial),
                      ),
                      child: entry.userProfileImageUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                entry.userProfileImageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildInitialAvatar(entry.userInitial);
                                },
                              ),
                            )
                          : _buildInitialAvatar(entry.userInitial),
                    ),
                    
                    // Athlete name
                    Expanded(
                      child: Text(
                        entry.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isCurrentUser ? Colors.orange : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Metric value (TIME, DISTANCE, etc.)
                    Text(
                      _getMetricValueText(entry),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser ? Colors.orange : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isActive ? Colors.orange : Colors.grey,
      ),
    );
  }

  String _getMetricHeaderText() {
    String? primaryMetric = leaderboard.primaryMetric;
    print('📊 LeaderboardWidget: Primary metric: $primaryMetric');
    
    if (primaryMetric != null) {
      switch (primaryMetric) {
        case 'distanceKm':
          return 'DISTANCE';
        case 'durationSeconds':
          return 'TIME';
        case 'elevation':
          return 'ELEVATION';
        case 'avgPace':
          return 'PACE';
        case 'steps':
          return 'STEPS';
        case 'calories':
          return 'CALORIES';
        default:
          return primaryMetric.toUpperCase();
      }
    }
    return 'TIME'; // Default
  }

  String _getMetricValueText(LeaderboardEntry entry) {
    String? primaryMetric = leaderboard.primaryMetric;
    print('📊 LeaderboardWidget: Getting value for metric: $primaryMetric');
    
    if (primaryMetric != null) {
      String value = entry.getFormattedValue(primaryMetric);
      print('📊 LeaderboardWidget: Formatted value: $value');
      return value;
    }
    
    // Default to time if no metric specified
    print('📊 LeaderboardWidget: No primary metric, defaulting to time');
    return entry.formattedTime;
  }

  Widget _buildInitialAvatar(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getProfileColor(String initial) {
    // Generate a consistent color based on the initial
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    int index = initial.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}
