import 'package:flutter/material.dart';
import 'services/firebase_teams_service.dart';
import 'models/team.dart';
import 'team_details_page.dart';
import 'discovered_team_details_page.dart';

class AllTeamsPage extends StatefulWidget {
  const AllTeamsPage({super.key});

  @override
  State<AllTeamsPage> createState() => _AllTeamsPageState();
}

class _AllTeamsPageState extends State<AllTeamsPage> {
  final FirebaseTeamsService _teamsService = FirebaseTeamsService();

  @override
  void initState() {
    super.initState();
    _teamsService.addListener(_onTeamsChanged);
    _loadTeams();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload teams every time the page becomes active
    _loadTeams();
  }

  @override
  void dispose() {
    _teamsService.removeListener(_onTeamsChanged);
    super.dispose();
  }

  void _onTeamsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTeams() async {
    try {
      await _teamsService.loadTeams();
    } catch (e) {
      print('Error loading teams: $e');
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'All Teams',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Header section with team count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Teams',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${_teamsService.myTeams.length} created • ${_teamsService.joinedTeams.length} joined',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_teamsService.myTeams.length + _teamsService.joinedTeams.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Teams grid
          Expanded(
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(20),
              child: _buildTeamsGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsGrid() {
    final allTeams = _getAllTeams();
    
    if (allTeams.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTeams,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No teams yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create or join some teams to see them here!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
      onRefresh: _loadTeams,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.85,
        ),
        itemCount: allTeams.length,
        itemBuilder: (context, index) {
          final team = allTeams[index];
          return _buildTeamCard(team);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getAllTeams() {
    List<Map<String, dynamic>> allTeams = [];
    
    // Add created teams from Firebase
    for (Team team in _teamsService.myTeams) {
      allTeams.add({
        'id': team.id,
        'name': team.name,
        'description': team.description,
        'members': team.memberCount.toString(),
        'creator': team.createdBy,
        'type': 'created',
        'teamObject': team, // Keep the original team object for navigation
      });
    }
    
    // Add joined teams from Firebase
    for (Team team in _teamsService.joinedTeams) {
      allTeams.add({
        'id': team.id,
        'name': team.name,
        'description': team.description,
        'members': team.memberCount.toString(),
        'creator': team.createdBy,
        'type': 'joined',
        'teamObject': team, // Keep the original team object for navigation
      });
    }
    
    return allTeams;
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    final isCreatedTeam = team['type'] == 'created';
    final teamObject = team['teamObject'] as Team;
    
    return GestureDetector(
      onTap: () {
        if (isCreatedTeam) {
          // Navigate to TeamDetailsPage for created teams
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailsPage(teamData: teamObject),
            ),
          );
        } else {
          // Navigate to DiscoveredTeamDetailsPage for joined teams
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscoveredTeamDetailsPage(
                teamData: {
                  'id': team['id'] ?? '',
                  'name': team['name'] ?? '',
                  'description': team['description'] ?? '',
                  'members': team['members'] ?? '0',
                  'creator': team['creator'] ?? '',
                },
                initialJoinedState: true,
              ),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Team icon/avatar with badge
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                  border: isCreatedTeam 
                    ? Border.all(color: Colors.orange, width: 3)
                    : null,
                ),
                child: Center(
                  child: _buildTeamIcon(team['name']?.toString() ?? ''),
                ),
              ),
              // Badge for created teams
              if (isCreatedTeam)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Owner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Badge for joined teams
              if (!isCreatedTeam)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Member',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Team name
          Text(
            team['name']?.toString() ?? 'Unknown Team',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Member count
          Text(
            '${team['members']} member${int.parse(team['members'] ?? '1') > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamIcon(String teamName) {
    // Create different icons based on team name
    switch (teamName.toLowerCase()) {
      case 'running club':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.directions_run,
            size: 30,
            color: Colors.white,
          ),
        );
      case 'swim':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.pool,
            size: 30,
            color: Colors.white,
          ),
        );
      case 'cycling enthusiasts':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.green[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.directions_bike,
            size: 30,
            color: Colors.white,
          ),
        );
      case 'yoga masters':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.purple[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.self_improvement,
            size: 30,
            color: Colors.white,
          ),
        );
      case 'fitness warriors':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.orange[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.fitness_center,
            size: 30,
            color: Colors.white,
          ),
        );
      default:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              teamName.isNotEmpty ? teamName[0].toUpperCase() : 'T',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
    }
  }
}
