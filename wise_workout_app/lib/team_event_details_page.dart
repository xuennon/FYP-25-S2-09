import 'package:flutter/material.dart';
import 'models/event.dart';
import 'models/team.dart';
import 'team_event_participants_page.dart';
import 'services/leaderboard_service.dart';
import 'services/firebase_user_profile_service.dart';

class TeamEventDetailsPage extends StatefulWidget {
  final Event event;
  final Team team;

  const TeamEventDetailsPage({
    super.key,
    required this.event,
    required this.team,
  });

  @override
  State<TeamEventDetailsPage> createState() => _TeamEventDetailsPageState();
}

class _TeamEventDetailsPageState extends State<TeamEventDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoadingLeaderboard = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Add method to refresh leaderboard data
  Future<void> _refreshLeaderboard() async {
    print('🔄 Refreshing leaderboard data...');
    await _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() {
        _isLoadingLeaderboard = true;
      });

      print('🔍 Loading leaderboard for team event: ${widget.event.id}');
      print('📊 Event primary metric: ${widget.event.primaryMetric}');
      print('📊 Event participants: ${widget.event.participants}');
      
      // Get leaderboard data from Firebase
      final leaderboardService = LeaderboardService();
      final eventLeaderboard = await leaderboardService.getEventLeaderboard(widget.event.id);
      
      if (eventLeaderboard != null && eventLeaderboard.entries.isNotEmpty) {
        print('📊 Found ${eventLeaderboard.entries.length} leaderboard entries');
        
        // Convert leaderboard entries to display format with real user data
        final leaderboardData = <Map<String, dynamic>>[];
        final userProfileService = FirebaseUserProfileService();
        
        for (int i = 0; i < eventLeaderboard.entries.length; i++) {
          final entry = eventLeaderboard.entries[i];
          
          // Get real user profile data
          final userProfile = await userProfileService.getUserProfileById(entry.userId);
          
          // Extract metrics from the entry
          final distance = (entry.metrics['distanceKm'] as num?)?.toDouble() ?? 0.0;
          final timeInSeconds = (entry.metrics['durationSeconds'] as int?) ?? 0;
          final timeInMinutes = (timeInSeconds / 60).round();
          final steps = (entry.metrics['steps'] as int?) ?? 0;
          
          leaderboardData.add({
            'userId': entry.userId,
            'username': userProfile?['username'] ?? entry.username ?? 'Unknown User',
            'email': userProfile?['email'] ?? 'No email',
            'profileImage': userProfile?['profileImage'] ?? entry.userProfileImageUrl,
            'distance': distance,
            'time': timeInMinutes,
            'steps': steps,
            'rank': i + 1, // Will be updated after sorting
          });
        }

        // Sort by primary metric based on event configuration
        final primaryMetric = widget.event.primaryMetric.toLowerCase();
        if (primaryMetric == 'distance') {
          leaderboardData.sort((a, b) => b['distance'].compareTo(a['distance']));
        } else if (primaryMetric == 'time') {
          // For time, lower is better (find in metrics which time field to use)
          leaderboardData.sort((a, b) => a['time'].compareTo(b['time']));
        } else if (primaryMetric == 'steps') {
          leaderboardData.sort((a, b) => b['steps'].compareTo(a['steps']));
        } else {
          // Default to distance
          leaderboardData.sort((a, b) => b['distance'].compareTo(a['distance']));
        }
        
        // Update ranks after sorting
        for (int i = 0; i < leaderboardData.length; i++) {
          leaderboardData[i]['rank'] = i + 1;
        }

        setState(() {
          _leaderboard = leaderboardData;
          _isLoadingLeaderboard = false;
        });

        print('✅ Loaded leaderboard with ${_leaderboard.length} participants');
      } else {
        print('📭 No leaderboard data found, creating placeholder entries for participants');
        
        // If no leaderboard data exists, create placeholder entries for participants
        final leaderboardData = <Map<String, dynamic>>[];
        final userProfileService = FirebaseUserProfileService();
        
        for (int i = 0; i < widget.event.participants.length; i++) {
          final participantId = widget.event.participants[i];
          
          // Get real user profile data
          final userProfile = await userProfileService.getUserProfileById(participantId);
          
          leaderboardData.add({
            'userId': participantId,
            'username': userProfile?['username'] ?? 'Unknown User',
            'email': userProfile?['email'] ?? 'No email',
            'profileImage': userProfile?['profileImage'],
            'distance': 0.0,
            'time': 0,
            'steps': 0,
            'rank': i + 1,
          });
        }

        setState(() {
          _leaderboard = leaderboardData;
          _isLoadingLeaderboard = false;
        });

        print('✅ Created placeholder leaderboard with ${_leaderboard.length} participants');
      }
    } catch (e) {
      print('❌ Error loading leaderboard: $e');
      setState(() {
        _leaderboard = [];
        _isLoadingLeaderboard = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.event.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshLeaderboard,
            tooltip: 'Refresh Leaderboard',
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade600,
                ],
              ),
            ),
            child: Column(
              children: [
                // Event Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _getEventIcon(widget.event.primarySport),
                ),
                const SizedBox(height: 16),
                
                // Event Name
                Text(
                  widget.event.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Team Name
                Text(
                  'Team: ${widget.team.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Event Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      icon: Icons.people,
                      label: 'Participants',
                      value: '${widget.event.participantCount}',
                    ),
                    _buildStatCard(
                      icon: Icons.sports,
                      label: 'Sports',
                      value: widget.event.sportsDisplay,
                    ),
                    _buildStatCard(
                      icon: Icons.calendar_today,
                      label: 'Duration',
                      value: _getEventDuration(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.orange,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Leaderboard'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Description
          if (widget.event.description.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.event.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Event Details
          const Text(
            'Event Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Start Date',
            value: _formatDate(widget.event.startDate),
          ),
          _buildDetailRow(
            icon: Icons.event,
            label: 'End Date',
            value: _formatDate(widget.event.endDate),
          ),
          _buildDetailRow(
            icon: Icons.sports,
            label: 'Sports',
            value: widget.event.sportsDisplay,
          ),
          _buildDetailRow(
            icon: Icons.track_changes,
            label: 'Primary Metric',
            value: widget.event.primaryMetric,
          ),
          _buildDetailRow(
            icon: Icons.people,
            label: 'Participants',
            value: '${widget.event.participantCount} members',
          ),
          
          const SizedBox(height: 24),
          
          // Participants Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamEventParticipantsPage(
                      event: widget.event,
                      teamData: widget.team,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.people, color: Colors.white),
              label: const Text(
                'View All Participants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLoadingLeaderboard) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Loading leaderboard...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_leaderboard.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshLeaderboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.leaderboard,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No leaderboard data yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Results will appear here once participants start tracking their progress.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshLeaderboard,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final participant = _leaderboard[index];
          return _buildLeaderboardCard(participant, index);
        },
      ),
    );
  }

  Widget _buildLeaderboardCard(Map<String, dynamic> participant, int index) {
    final rank = participant['rank'] ?? index + 1;
    final isTopThree = rank <= 3;
    
    Color rankColor = Colors.grey[600]!;
    IconData? medalIcon;
    
    if (rank == 1) {
      rankColor = Colors.amber[700]!;
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[600]!;
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.orange[800]!;
      medalIcon = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopThree ? rankColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isTopThree 
          ? Border.all(color: rankColor.withOpacity(0.3), width: 1)
          : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank or Medal
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree ? rankColor.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: isTopThree && medalIcon != null
                ? Icon(medalIcon, color: rankColor, size: 20)
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTopThree ? rankColor : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          
          // User Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange[100],
            child: Text(
              participant['username']?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant['username'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  participant['email'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Metric Value - Show only the primary metric being tracked
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPrimaryMetricDisplay(participant, isTopThree, rankColor),
              if (_shouldShowSecondaryMetric()) 
                _buildSecondaryMetricDisplay(participant),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetricDisplay(Map<String, dynamic> participant, bool isTopThree, Color rankColor) {
    // Get the actual primary metric, prioritizing root-level field
    String actualPrimaryMetric;
    if (widget.event.primaryMetricFromRoot != null && widget.event.primaryMetricFromRoot!.isNotEmpty) {
      actualPrimaryMetric = widget.event.primaryMetricFromRoot!.toLowerCase();
      print('🎯 Display Debug: Event "${widget.event.name}" - Using root-level primaryMetric: "$actualPrimaryMetric"');
    } else {
      actualPrimaryMetric = widget.event.primaryMetric.toLowerCase();
      print('🎯 Display Debug: Event "${widget.event.name}" - Using computed primaryMetric: "$actualPrimaryMetric"');
    }
    
    print('   Firebase root primaryMetric: "${widget.event.primaryMetricFromRoot}"');
    print('   Event model primaryMetric: "${widget.event.primaryMetric}"');
    print('   Final metric used: "$actualPrimaryMetric"');
    print('   Participant data: $participant');
    
    String value;
    String unit;
    
    switch (actualPrimaryMetric) {
      case 'distance':
        value = '${participant['distance']?.toStringAsFixed(2) ?? '0.00'}';
        unit = 'km';
        print('📏 Showing distance: $value $unit');
        break;
      case 'time':
      case 'duration':
      case 'durationseconds':
        value = '${participant['time'] ?? 0}';
        unit = 'min';
        print('⏱️ Showing time: $value $unit');
        break;
      case 'steps':
        value = '${participant['steps'] ?? 0}';
        unit = 'steps';
        print('👟 Showing steps: $value $unit');
        break;
      default:
        // Let's check what we actually got and show distance if the event name suggests it's distance-based
        print('❓ Unknown primary metric: "$actualPrimaryMetric", event name: "${widget.event.name}"');
        if (widget.event.name.toLowerCase().contains('distance') || 
            widget.event.name.toLowerCase().contains('km') ||
            widget.event.name.toLowerCase().contains('run') ||
            actualPrimaryMetric.contains('distance')) {
          value = '${participant['distance']?.toStringAsFixed(2) ?? '0.00'}';
          unit = 'km';
          print('📏 Defaulting to distance based on event name: $value $unit');
        } else if (widget.event.name.toLowerCase().contains('time') || 
            widget.event.name.toLowerCase().contains('duration') ||
            actualPrimaryMetric.contains('time') || 
            actualPrimaryMetric.contains('duration')) {
          value = '${participant['time'] ?? 0}';
          unit = 'min';
          print('⏱️ Defaulting to time based on event name: $value $unit');
        } else {
          // Default to distance for running events
          value = '${participant['distance']?.toStringAsFixed(2) ?? '0.00'}';
          unit = 'km';
          print('📏 Final fallback to distance: $value $unit');
        }
    }
    
    return Text(
      '$value $unit',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isTopThree ? rankColor : Colors.black,
      ),
    );
  }

  bool _shouldShowSecondaryMetric() {
    // For now, let's only show primary metric as requested
    // You can modify this logic if you want to show secondary metrics for some cases
    return false;
  }

  Widget _buildSecondaryMetricDisplay(Map<String, dynamic> participant) {
    // This method is for potential future use if you want to show secondary metrics
    return Text(
      '${participant['time'] ?? 0} min',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getEventIcon(String sportType) {
    IconData iconData;
    switch (sportType.toLowerCase()) {
      case 'run':
        iconData = Icons.directions_run;
        break;
      case 'ride':
        iconData = Icons.directions_bike;
        break;
      case 'swim':
        iconData = Icons.pool;
        break;
      case 'walk':
        iconData = Icons.directions_walk;
        break;
      case 'hike':
        iconData = Icons.hiking;
        break;
      default:
        iconData = Icons.sports;
    }
    return Icon(
      iconData,
      size: 40,
      color: Colors.white,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getEventDuration() {
    final duration = widget.event.endDate.difference(widget.event.startDate);
    if (duration.inDays > 0) {
      return '${duration.inDays} days';
    } else {
      return '${duration.inHours} hours';
    }
  }
}
