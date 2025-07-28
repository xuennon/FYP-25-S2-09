import 'package:flutter/material.dart';
import 'search_page.dart';
import 'friend_list_page.dart';
import 'settings_page.dart';
import 'create_team_page.dart';
import 'my_profile_page.dart';
import 'user_home_page.dart';
import 'team_details_page.dart';
import 'team_state.dart';
import 'joined_teams_state.dart';
import 'discovered_team_details_page.dart';
import 'widgets/user_avatar.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedSportType = 'All';
  final TeamState _teamState = TeamState(); // Use TeamState instead of local variable
  final JoinedTeamsState _joinedTeamsState = JoinedTeamsState(); // Global joined teams state
  
  final List<String> sportTypes = ['All', 'Run', 'Ride', 'Swim', 'Walk', 'Hike'];
  
  final List<Challenge> activeChallenges = [
    Challenge(
      id: '1',
      name: 'July 5K x Brooks Challenge',
      description: 'Complete a 5 km run',
      iconPath: 'assets/challenge_5k.png',
      isActive: true,
    ),
    Challenge(
      id: '2',
      name: 'Le Col Level Up Challenge',
      description: 'Level up your cycling',
      iconPath: 'assets/challenge_levelup.png',
      isActive: true,
    ),
  ];
  
  final List<Challenge> availableChallenges = [
    Challenge(
      id: '3',
      name: 'July 10K x Runna Challenge',
      description: 'Complete a 10 km (6.2 mi) run.',
      dateRange: 'Jul 1 to Jul 31, 2025',
      iconPath: 'assets/challenge_10k.png',
      actionText: 'Join',
      actionColor: Colors.orange,
    ),
    Challenge(
      id: '4',
      name: 'Virtual TCS New York City Marathon',
      description: 'Complete the Virtual TCS New York City Marathon between October 25 and November 2, 2025.',
      dateRange: 'Oct 25 to Nov 2, 2025',
      iconPath: 'assets/challenge_marathon.png',
      actionText: 'Register',
      actionColor: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Start with Challenges tab
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will trigger a rebuild when returning to this page
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  _buildChallengesTab(),
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
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Challenges'),
          Tab(text: 'Team'),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    return const Center(
      child: Text(
        'Active Tab Content',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildChallengesTab() {
    return Column(
      children: [
        _buildSportFilters(),
        const SizedBox(height: 16),
        if (activeChallenges.isNotEmpty) ...[
          _buildSectionTitle('Active Challenges'),
          _buildActiveChallenges(),
          const SizedBox(height: 12),
        ],
        _buildAvailableChallenges(),
      ],
    );
  }

  Widget _buildTeamTab() {
    final joinedTeams = _joinedTeamsState.getAllJoinedTeams();
    final hasCreatedTeam = _teamState.hasTeam();
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
                  'Create your own fitness club',
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
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateTeamPage()),
                  );
                  
                  if (result != null && result is Map<String, String>) {
                    setState(() {
                      _teamState.setTeam(result);
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Team "${result['name']}" created successfully!')),
                      );
                    }
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
          
          const SizedBox(height: 40),
          
          // Teams list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Created team section
                  if (hasCreatedTeam) ...[
                    const Text(
                      'My Team',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamDetailsPage(teamData: _teamState.createdTeam!),
                          ),
                        );
                      },
                      child: _buildTeamCard(
                        teamData: _teamState.createdTeam!,
                        isOwned: true,
                      ),
                    ),
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
                                teamData: teamData,
                                initialJoinedState: true,
                              ),
                            ),
                          );
                        },
                        child: _buildTeamCard(
                          teamData: teamData,
                          isOwned: false,
                        ),
                      ),
                    )).toList(),
                  ],
                  
                  // Empty state
                  if (!hasCreatedTeam && !hasJoinedTeams) ...[
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

  Widget _buildActiveChallenges() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activeChallenges.length,
        itemBuilder: (context, index) {
          final challenge = activeChallenges[index];
          return Container(
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
                    child: _getChallengeIcon(challenge.name),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.name.split(' ').take(2).join(' '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableChallenges() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: availableChallenges.length,
        itemBuilder: (context, index) {
          final challenge = availableChallenges[index];
          return Container(
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _getChallengeIcon(challenge.name),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, size: 12),
                      SizedBox(width: 4),
                      Icon(Icons.sports, size: 12),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      challenge.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (challenge.dateRange != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      challenge.dateRange!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        _joinChallenge(challenge);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: challenge.actionColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        challenge.actionText ?? 'Join',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getChallengeIcon(String challengeName) {
    if (challengeName.contains('5K')) {
      return const Center(
        child: Text(
          '5K',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    } else if (challengeName.contains('10K')) {
      return const Center(
        child: Text(
          '10K',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    } else if (challengeName.contains('Level Up')) {
      return const Icon(Icons.trending_up, size: 24);
    } else if (challengeName.contains('Marathon')) {
      return const Icon(Icons.flag, size: 24);
    }
    return const Icon(Icons.sports, size: 24);
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.grey[600], size: 28),
              const Text(
                'Post',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
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

  void _joinChallenge(Challenge challenge) {
    setState(() {
      // Move challenge to active challenges
      availableChallenges.remove(challenge);
      activeChallenges.add(Challenge(
        id: challenge.id,
        name: challenge.name,
        description: challenge.description,
        iconPath: challenge.iconPath,
        isActive: true,
      ));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined ${challenge.name}!')),
    );
  }
}

class Challenge {
  final String id;
  final String name;
  final String description;
  final String? dateRange;
  final String iconPath;
  final bool isActive;
  final String? actionText;
  final Color? actionColor;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    this.dateRange,
    required this.iconPath,
    this.isActive = false,
    this.actionText,
    this.actionColor,
  });
}
