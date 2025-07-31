import 'package:flutter/material.dart';

class DiscoveredTeamDetailsPage extends StatefulWidget {
  final Map<String, String> teamData;
  final bool initialJoinedState;
  
  const DiscoveredTeamDetailsPage({
    super.key, 
    required this.teamData,
    this.initialJoinedState = false,
  });

  @override
  State<DiscoveredTeamDetailsPage> createState() => _DiscoveredTeamDetailsPageState();
}

class _DiscoveredTeamDetailsPageState extends State<DiscoveredTeamDetailsPage> {
  late bool isJoined;

  @override
  void initState() {
    super.initState();
    // Use the initial state passed from the parent
    isJoined = widget.initialJoinedState;
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
            Navigator.pop(context, isJoined); // Return the joined state
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Image
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.flag,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Team Name
                  Text(
                    widget.teamData['name'] ?? 'Team Name',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Member Count
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.teamData['members']} Member${int.parse(widget.teamData['members'] ?? '1') > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.person_add,
                      label: isJoined ? 'Joined' : 'Join',
                      backgroundColor: isJoined ? Colors.grey : Colors.orange,
                      onTap: () async {
                        setState(() {
                          isJoined = !isJoined;
                        });
                        
                        // Note: In a full Firebase implementation, you would:
                        // if (isJoined) {
                        //   await _teamsService.joinTeam(teamId);
                        // } else {
                        //   await _teamsService.leaveTeam(teamId);
                        // }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isJoined 
                                  ? 'Joined ${widget.teamData['name']}!' 
                                  : 'Left ${widget.teamData['name']}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      backgroundColor: Colors.grey[100]!,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share team coming soon!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.info_outline,
                      label: 'Overview',
                      backgroundColor: Colors.grey[100]!,
                      onTap: () {
                        _showTeamOverview();
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Events Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'No upcoming events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Placeholder Event Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This team hasn\'t created any events yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Team Description Section
            if (widget.teamData['description']?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Team',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.teamData['description']!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: label == 'Join' || label == 'Joined' 
                    ? backgroundColor 
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: label == 'Join' 
                    ? Colors.white 
                    : label == 'Joined' 
                        ? Colors.white 
                        : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: label == 'Join' || label == 'Joined' 
                    ? Colors.white 
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamOverview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Team Overview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Team: ${widget.teamData['name']}'),
              const SizedBox(height: 8),
              Text('Members: ${widget.teamData['members']}'),
              const SizedBox(height: 8),
              const Text('Events: 0'),
              const SizedBox(height: 8),
              const Text('Status: Public'),
              if (widget.teamData['description']?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const Text('Description:'),
                const SizedBox(height: 4),
                Text(widget.teamData['description']!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
