import 'package:flutter/material.dart';
import 'dart:async';
import 'search_page.dart';
import 'friend_list_page.dart';
import 'settings_page.dart';
import 'create_team_page.dart';
import 'my_profile_page.dart';
import 'user_home_page.dart';
import 'write_post_page.dart';
import 'team_details_page.dart';
import 'team_state.dart';
import 'services/firebase_teams_service.dart';
import 'models/team.dart';
import 'discovered_team_details_page.dart';
import 'widgets/user_avatar.dart';
import 'services/firebase_events_service.dart';
import 'services/firebase_programs_service.dart';
import 'models/event.dart';
import 'event_details_page.dart';
import 'program_details_page.dart';
import 'joined_events_state.dart';
import 'all_events_page.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedSportType = 'All';
  String selectedProgramCategory = 'All';
  final TeamState _teamState = TeamState();
  final FirebaseTeamsService _teamsService = FirebaseTeamsService();
  final JoinedEventsState _joinedEventsState = JoinedEventsState();
  final FirebaseEventsService _eventsService = FirebaseEventsService();
  final FirebaseProgramsService _programsService = FirebaseProgramsService();
  Timer? _refreshTimer;
  
  final List<String> sportTypes = ['All', 'Run', 'Ride', 'Swim', 'Walk', 'Hike'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Start with Events tab
    _eventsService.addListener(_onEventsChanged);
    _programsService.addListener(_onProgramsChanged);
    _joinedEventsState.addListener(_onJoinedEventsChanged);
    _teamsService.addListener(_onTeamsChanged);
    
    // Start real-time listening for programs and teams
    _programsService.startListening();
    _teamsService.startListening();
    
    _loadEvents();
    _loadPrograms();
    _loadTeams();
    
    // Set up automatic refresh every 30 seconds to check for new events and programs
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadEvents();
        _loadPrograms();
        _loadTeams();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload events every time the page becomes active
    // This ensures fresh data when business users create new events
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventsService.removeListener(_onEventsChanged);
    _programsService.removeListener(_onProgramsChanged);
    _joinedEventsState.removeListener(_onJoinedEventsChanged);
    _teamsService.removeListener(_onTeamsChanged);
    _refreshTimer?.cancel(); // Cancel the timer when disposing
    
    // Stop real-time listening for programs and teams
    _programsService.stopListening();
    _teamsService.stopListening();
    
    super.dispose();
  }

  void _onEventsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onProgramsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onJoinedEventsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTeamsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPrograms() async {
    try {
      print('🔄 Event page: Starting to load programs...');
      await _programsService.loadPrograms();
      if (mounted) {
        print('🔄 Programs refreshed at ${DateTime.now()}');
        print('📚 Total programs loaded: ${_programsService.allPrograms.length}');
        setState(() {}); // Force rebuild to show programs
      }
    } catch (e) {
      print('❌ Error loading programs: $e');
      if (mounted) {
        // Don't show error snackbar for permission issues - just show empty state
        setState(() {}); // Update UI to show empty state
      }
    }
  }

  Future<void> _loadTeams() async {
    try {
      print('🔄 Event page: Starting to load teams...');
      await _teamsService.loadTeams();
      if (mounted) {
        print('🔄 Teams refreshed at ${DateTime.now()}');
        print('👥 Total teams loaded: ${_teamsService.allTeams.length}');
        setState(() {}); // Force rebuild to show teams
      }
    } catch (e) {
      print('❌ Error loading teams: $e');
      if (mounted) {
        setState(() {}); // Update UI to show empty state
      }
    }
  }

  Future<void> _loadEvents() async {
    try {
      print('🔄 Event page: Starting to load events...');
      await _eventsService.loadEvents();
      if (mounted) {
        print('🔄 Events refreshed at ${DateTime.now()}');
        print('📊 Total events loaded: ${_eventsService.allEvents.length}');
        
        // Debug: Print each event
        for (var event in _eventsService.allEvents) {
          print('� Event: ${event.name} | Sport: ${event.sportType} | Business: ${event.businessName}');
        }
        
        setState(() {}); // Force rebuild to show events
      }
    } catch (e) {
      print('❌ Error loading events: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load events: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Close dialog and navigate to login page
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveTab(),
                  _buildEventsTab(),
                  _buildTeamTab(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Profile and Search
          Row(
            children: [
              UserAvatar(
                radius: 20,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyProfilePage()),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
              ),
            ],
          ),
          // Center - Upgrade Button
          ElevatedButton(
            onPressed: () {
              // TODO: Implement upgrade functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Right side - Settings and Logout
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: _handleLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.orange,
        indicatorWeight: 3,
        onTap: (index) {
          // Refresh data when switching to specific tabs
          if (index == 0) { // Programs tab
            _loadPrograms();
          } else if (index == 1) { // Events tab
            _loadEvents();
          } else if (index == 2) { // Team tab
            _loadTeams();
          }
        },
        tabs: const [
          Tab(text: 'Programs'),
          Tab(text: 'Events'),
          Tab(text: 'Team'),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    return Column(
      children: [
        // Programs header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Training Programs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Row(
                children: [
                  if (_programsService.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _loadPrograms,
                      tooltip: 'Refresh programs',
                    ),
                  Text(
                    '${_programsService.allPrograms.length} programs',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildProgramCategoryFilters(),
        const SizedBox(height: 16),
        if (_programsService.isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _buildProgramsList(),
      ],
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        // Events header with refresh button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Row(
                children: [
                  // My Events button
                  TextButton.icon(
                    icon: const Icon(Icons.event_available, size: 18),
                    label: const Text('My Events'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllEventsPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_eventsService.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _loadEvents,
                      tooltip: 'Refresh events',
                    ),
                  Text(
                    '${_eventsService.allEvents.length} events',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildSportFilters(),
        const SizedBox(height: 16),
        if (_eventsService.isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          // Always show Active Events section if there are any joined events
          if (_joinedEventsState.joinedEventIds.isNotEmpty) ...[
            _buildSectionTitle('Active Events'),
            _buildActiveEvents(),
            const SizedBox(height: 12),
          ],
          _buildAvailableEvents(),
        ],
      ],
    );
  }

  Widget _buildTeamTab() {
    return StreamBuilder<List<Team>>(
      stream: _teamsService.getTeamsStream(),
      builder: (context, snapshot) {
        final allTeams = snapshot.data ?? [];
        final currentUserId = _teamsService.currentUserId;
        
        // Teams created by current user
        final createdTeams = allTeams.where((team) => 
          team.createdBy == currentUserId).toList();
        
        // Teams joined by current user (but not created by them)
        final joinedTeams = allTeams.where((team) => 
          _teamsService.isTeamMember(team.id) && team.createdBy != currentUserId).toList();
          
        final hasCreatedTeams = createdTeams.isNotEmpty;
        final hasJoinedTeams = joinedTeams.isNotEmpty;
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with text and button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Create your own fitness team',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  print('🔄 Create team button pressed');
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateTeamPage()),
                  );
                  
                  print('🔄 Team creation result: $result');
                  
                  if (result != null && result is Map<String, dynamic>) {
                    print('✅ Team created successfully: ${result['name']}');
                    
                    // Update local team state for backward compatibility
                    setState(() {
                      _teamState.setTeam({
                        'name': result['name'] ?? '',
                        'description': result['description'] ?? '',
                        'teamId': result['teamId'] ?? '',
                      });
                    });
                    
                    // Reload teams from Firebase to show the newly created team
                    print('🔄 Reloading teams from Firebase...');
                    await _loadTeams();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Team "${result['name']}" created successfully!')),
                      );
                    }
                  } else {
                    print('❌ Team creation was cancelled or failed');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.orange, width: 1),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create team',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          
          // Teams header with refresh button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Teams',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    if (_teamsService.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _loadTeams,
                        tooltip: 'Refresh teams',
                      ),
                    Text(
                      '${createdTeams.length + joinedTeams.length} teams',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Teams list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Created teams section
                  if (hasCreatedTeams) ...[
                    const Text(
                      'My Teams',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...createdTeams.map((team) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamDetailsPage(teamData: team),
                            ),
                          );
                        },
                        child: _buildTeamCard(
                          teamData: {
                            'name': team.name,
                            'description': team.description,
                            'members': team.memberCount.toString(),
                            'creator': team.createdBy,
                          },
                          isOwned: true,
                        ),
                      ),
                    )).toList(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Joined teams section
                  if (hasJoinedTeams) ...[
                    const Text(
                      'Joined Teams',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...joinedTeams.map((teamData) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiscoveredTeamDetailsPage(
                                teamData: {
                                  'id': teamData.id, // Add the team ID
                                  'name': teamData.name,
                                  'description': teamData.description,
                                  'members': teamData.memberCount.toString(),
                                  'creator': teamData.createdBy,
                                },
                                initialJoinedState: true,
                              ),
                            ),
                          );
                        },
                        child: _buildTeamCard(
                          teamData: {
                            'name': teamData.name,
                            'description': teamData.description,
                            'members': teamData.memberCount.toString(),
                            'creator': teamData.createdBy,
                          },
                          isOwned: false,
                        ),
                      ),
                    )).toList(),
                  ],
                  
                  // Empty state
                  if (!hasCreatedTeams && !hasJoinedTeams) ...[
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Icon(
                            Icons.group_add,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No teams yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your own team or join existing ones',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTeamCard({
    required Map<String, String> teamData,
    required bool isOwned,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isOwned ? Colors.blue[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.flag,
              size: 30,
              color: isOwned ? Colors.blue : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamData['name']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${teamData['members'] ?? '1'} Member${(int.tryParse(teamData['members'] ?? '1') ?? 1) > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!isOwned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Joined',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildSportFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sportTypes.length,
        itemBuilder: (context, index) {
          final sportType = sportTypes[index];
          final isSelected = selectedSportType == sportType;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sportType != 'All') _getSportIcon(sportType),
                  if (sportType != 'All') const SizedBox(width: 4),
                  Text(sportType),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedSportType = sportType;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.orange.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.orange : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getSportIcon(String sportType) {
    IconData iconData;
    switch (sportType) {
      case 'Run':
        iconData = Icons.directions_run;
        break;
      case 'Ride':
        iconData = Icons.directions_bike;
        break;
      case 'Swim':
        iconData = Icons.pool;
        break;
      case 'Walk':
        iconData = Icons.directions_walk;
        break;
      case 'Hike':
        iconData = Icons.hiking;
        break;
      default:
        iconData = Icons.sports;
    }
    return Icon(iconData, size: 16);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveEvents() {
    // For active events, always show ALL joined events regardless of sport filter
    // This ensures users can see all their active events at once
    final allEvents = _eventsService.allEvents;
    // Show only joined events as active events
    final activeEvents = allEvents.where((event) => _joinedEventsState.isEventJoined(event.id)).toList();
    
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activeEvents.length,
        itemBuilder: (context, index) {
          final event = activeEvents[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(event: event),
                ),
              );
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Transform.scale(
                      scale: 0.8,
                      child: _getEventIcon(event.sportType),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.name.split(' ').take(2).join(' '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableEvents() {
    final allEvents = _eventsService.getEventsBySportType(selectedSportType);
    // Filter out joined events
    final availableEvents = allEvents.where((event) => !_joinedEventsState.isEventJoined(event.id)).toList();
    
    if (availableEvents.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No events available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedSportType == 'All' 
                    ? 'Check back later for new events'
                    : 'No $selectedSportType events available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadEvents,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: availableEvents.length,
          itemBuilder: (context, index) {
            final event = availableEvents[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailsPage(event: event),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event icon with default logo
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _getEventIcon(event.sportType),
                      ),
                      const SizedBox(height: 8),
                      // Event name
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Business name
                      Text(
                        'by ${event.businessName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Event description
                      Expanded(
                        child: Text(
                          event.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Event date range
                      const SizedBox(height: 4),
                      Text(
                        event.dateRange,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Join button
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: event.isFull ? null : () {
                            _joinEvent(event);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: event.isFull ? Colors.grey : Colors.orange,
                            foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            event.isFull ? 'Full' : 'Join',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getEventIcon(String sportType) {
    IconData iconData;
    switch (sportType) {
      case 'Run':
        iconData = Icons.directions_run;
        break;
      case 'Ride':
        iconData = Icons.directions_bike;
        break;
      case 'Swim':
        iconData = Icons.pool;
        break;
      case 'Walk':
        iconData = Icons.directions_walk;
        break;
      case 'Hike':
        iconData = Icons.hiking;
        break;
      default:
        iconData = Icons.event;
    }
    return Icon(iconData, size: 24, color: Colors.orange);
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserHomePage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, color: Colors.grey[600], size: 28),
                const Text(
                  'Home',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendListPage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people, color: Colors.grey[600], size: 28),
                const Text(
                  'Friend',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WritePostPage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.grey[600], size: 28),
                const Text(
                  'Post',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, color: Colors.black, size: 28),
              Text(
                'Event',
                style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyProfilePage()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, color: Colors.grey[600], size: 28),
                const Text(
                  'Profile',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinEvent(Event event) async {
    try {
      // Update joined events state immediately for instant UI update
      _joinedEventsState.joinEvent(event.id);
      
      bool success = await _eventsService.joinEvent(event.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined ${event.name}!')),
        );
      } else {
        // If the server call failed, revert the state change
        _joinedEventsState.leaveEvent(event.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join event. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // If there was an error, revert the state change
      _joinedEventsState.leaveEvent(event.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProgramCategoryFilters() {
    final categories = _programsService.getAvailableCategories();
    
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedProgramCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedProgramCategory = category;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.orange.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.orange : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramsList() {
    final programs = _programsService.getProgramsByCategory(selectedProgramCategory);
    
    if (programs.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No programs available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedProgramCategory == 'All' 
                    ? 'Check back later for new programs'
                    : 'No $selectedProgramCategory programs available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadPrograms,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: programs.length,
          itemBuilder: (context, index) {
            final program = programs[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProgramDetailsPage(program: program),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Program image/icon
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: program.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  program.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.fitness_center,
                                      size: 40,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.fitness_center,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Program name
                      Text(
                        program.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      
                      // Duration
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              program.duration,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
