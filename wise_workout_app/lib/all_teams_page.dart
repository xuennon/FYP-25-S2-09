import 'package:flutter/material.dart';
import 'joined_teams_state.dart';
import 'team_state.dart';

class AllTeamsPage extends StatefulWidget {
  const AllTeamsPage({super.key});

  @override
  State<AllTeamsPage> createState() => _AllTeamsPageState();
}

class _AllTeamsPageState extends State<AllTeamsPage> {
  final JoinedTeamsState _joinedTeamsState = JoinedTeamsState();
  final TeamState _teamState = TeamState();

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
                      '${_teamState.hasTeam() ? "1 created" : "0 created"} • ${_joinedTeamsState.getAllJoinedTeams().length} joined',
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
                    '${_getAllTeams().length}',
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
      return const Center(
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
          ],
        ),
      );
    }

    return GridView.builder(
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
    );
  }

  List<Map<String, String>> _getAllTeams() {
    List<Map<String, String>> allTeams = [];
    
    // Add created team (if any)
    if (_teamState.hasTeam()) {
      final createdTeam = Map<String, String>.from(_teamState.createdTeam!);
      createdTeam['type'] = 'created'; // Add a flag to distinguish
      allTeams.add(createdTeam);
    }
    
    // Add joined teams
    final joinedTeams = _joinedTeamsState.getAllJoinedTeams();
    for (var team in joinedTeams) {
      final teamCopy = Map<String, String>.from(team);
      teamCopy['type'] = 'joined'; // Add a flag to distinguish
      allTeams.add(teamCopy);
    }
    
    return allTeams;
  }

  Widget _buildTeamCard(Map<String, String> team) {
    final isCreatedTeam = team['type'] == 'created';
    
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped on ${team['name']} (${isCreatedTeam ? 'Created' : 'Joined'})')),
        );
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
                  child: _buildTeamIcon(team['name']!),
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
            ],
          ),
          const SizedBox(height: 12),
          // Team name
          Text(
            team['name']!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
