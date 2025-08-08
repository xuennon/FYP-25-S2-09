import 'package:flutter/material.dart';
import 'edit_team_page.dart';
import 'team_state.dart';
import 'models/team.dart';
import 'services/firebase_teams_service.dart';

class TeamDetailsPage extends StatefulWidget {
  final Team teamData;
  
  const TeamDetailsPage({super.key, required this.teamData});

  @override
  State<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  late Team currentTeamData;
  final TeamState _teamState = TeamState();
  final FirebaseTeamsService _teamsService = FirebaseTeamsService();

  @override
  void initState() {
    super.initState();
    currentTeamData = widget.teamData;
  }  @override
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              _showTeamSettings();
            },
          ),
        ],
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
                    currentTeamData.name,
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
                        '${currentTeamData.memberCount} Members',
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
                      icon: Icons.edit,
                      label: 'Edit Team Details',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTeamPage(teamData: currentTeamData),
                          ),
                        );
                        
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            // Update the team data with the edited information
                            currentTeamData = currentTeamData.copyWith(
                              name: result['name'],
                              description: result['description'],
                            );
                            // Update the global state with the Map format for compatibility
                            _teamState.updateTeam({
                              'name': result['name'],
                              'description': result['description'],
                            });
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () {
                        _shareTeam();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.info_outline,
                      label: 'Overview',
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'No upcoming events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Create event coming soon!')),
                      );
                    },
                    child: const Text(
                      'Create an event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
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
                    'Create your first team event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organize activities and challenges for your team members',
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
            if (currentTeamData.description.isNotEmpty) ...[
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
                      currentTeamData.description,
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamSettings() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Team Info'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit team info coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Invite Members'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite members coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Team', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
        );
      },
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
              Text('Team: ${currentTeamData.name}'),
              const SizedBox(height: 8),
              Text('Members: ${currentTeamData.memberCount}'),
              const SizedBox(height: 8),
              const Text('Events: 0'),
              const SizedBox(height: 8),
              Text('Created: ${currentTeamData.createdAt.toString().split(' ')[0]}'),
              if (currentTeamData.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Description:'),
                const SizedBox(height: 4),
                Text(currentTeamData.description),
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Team'),
          content: Text('Are you sure you want to delete "${currentTeamData.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog first
                
                print('🔄 Attempting to delete team: ${currentTeamData.name} with ID: ${currentTeamData.id}');
                print('🔄 Current user ID: ${_teamsService.currentUserId}');
                print('🔄 Team created by: ${currentTeamData.createdBy}');
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );
                
                try {
                  // Delete team from Firebase
                  bool success = await _teamsService.deleteTeam(currentTeamData.id);
                  
                  print('🔄 Delete team result: $success');
                  
                  // Close loading indicator
                  if (mounted) Navigator.of(context).pop();
                  
                  if (success) {
                    // Also remove from local state for immediate UI update
                    _teamState.deleteTeam();
                    
                    if (mounted) {
                      Navigator.of(context).pop(); // Go back to Event page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Team deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete team. You may not have permission to delete this team.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  print('❌ Exception during team deletion: $e');
                  // Close loading indicator
                  if (mounted) Navigator.of(context).pop();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting team: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _shareTeam() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Copy to Clipboard option
                    _buildShareOption(
                      icon: Icons.copy, 
                      label: 'Copy to\nClipboard', 
                      backgroundColor: const Color(0xFFF2F2F0),
                      onTap: () {
                        // Generate a link for the current team
                        String teamLink = 'https://wiseworkout.com/teams/${currentTeamData.name.replaceAll(' ', '_').toLowerCase()}';
                        
                        // Copy to clipboard
                        // In a real app, you would use package:flutter/services.dart to access the clipboard
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Team link copied to clipboard: $teamLink')),
                        );
                      }
                    ),
                    
                    // Share To option
                    _buildShareOption(
                      icon: Icons.share, 
                      label: 'Share\nTo', 
                      backgroundColor: const Color(0xFFF2F2F0),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showSocialShareDialog();
                      }
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSocialShareDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share via',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildSocialMediaButton(
                      icon: 'X',
                      label: 'Post',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Team shared to X (Twitter)')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: null,
                      iconData: Icons.facebook,
                      label: 'Facebook',
                      backgroundColor: const Color(0xFF1877F2),
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Team shared to Facebook')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: null,
                      iconData: Icons.chat_bubble,
                      label: 'WhatsApp',
                      backgroundColor: const Color(0xFF25D366),
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Team shared to WhatsApp')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: 'Ig',
                      label: 'Instagram',
                      backgroundColor: Colors.purple,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Team shared to Instagram')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: null,
                      iconData: Icons.message,
                      label: 'Message',
                      backgroundColor: Colors.blue,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Team shared via Messages')),
                        );
                      }
                    ),
                    _buildSocialMediaButton(
                      icon: null,
                      iconData: Icons.email,
                      label: 'Email',
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Team shared via Email')),
                        );
                      }
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSocialMediaButton({
    String? icon,
    IconData? iconData,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: icon != null
                ? Text(
                    icon,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Icon(
                    iconData,
                    color: textColor,
                    size: 36,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
