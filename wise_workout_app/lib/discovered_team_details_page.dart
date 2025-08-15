import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_teams_service.dart';
import 'services/firebase_events_service.dart';
import 'team_members_page.dart';
import 'team_event_details_page.dart';
import 'models/team.dart';
import 'models/event.dart';
import 'joined_events_state.dart';

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
  final FirebaseTeamsService _teamsService = FirebaseTeamsService();
  final FirebaseEventsService _eventsService = FirebaseEventsService();
  List<Event> _teamEvents = [];

  @override
  void initState() {
    super.initState();
    // Use the initial state passed from the parent
    isJoined = widget.initialJoinedState;
    _loadTeamEvents();
  }

  Future<void> _handleEventJoinLeave(Event event) async {
    try {
      // Check if user is authenticated
      final currentUserId = _eventsService.currentUserId;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to join events'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Update event participants in Firebase
        final updatedParticipants = List<String>.from(event.participants);
        final joinedEventsState = JoinedEventsState();
        
        if (event.isActive) {
          // User is leaving the event
          updatedParticipants.remove(currentUserId);
          print('🔄 User leaving event: ${event.name}');
          
          // Remove from joined events state for workout syncing
          joinedEventsState.leaveEvent(event.id);
        } else {
          // User is joining the event
          if (!updatedParticipants.contains(currentUserId)) {
            updatedParticipants.add(currentUserId);
          }
          print('🔄 User joining event: ${event.name}');
          
          // Add to joined events state for workout syncing
          joinedEventsState.joinEvent(event.id);
        }

        // Update in Firebase
        await FirebaseFirestore.instance
            .collection('events')
            .doc(event.id)
            .update({'participants': updatedParticipants});

        // Update local event object
        event.participants.clear();
        event.participants.addAll(updatedParticipants);
        event.isActive = updatedParticipants.contains(currentUserId);

        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Refresh the events list
        await _loadTeamEvents();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event.isActive 
                ? 'Successfully joined "${event.name}"!' 
                : 'Left "${event.name}"',
            ),
            backgroundColor: event.isActive ? Colors.green : Colors.orange,
          ),
        );

        print('✅ Event participation updated successfully');
        print('📊 JoinedEventsState now contains: ${joinedEventsState.joinedEventIds}');

      } catch (e) {
        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        print('❌ Error updating event participation: $e');
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Unexpected error in _handleEventJoinLeave: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadTeamEvents() async {
    try {
      final teamId = widget.teamData['id'];
      if (teamId != null) {
        print('🔄 [Discovered Team] Loading team events for: ${widget.teamData['name']} ($teamId)');
        
        final teamEvents = await _eventsService.loadTeamEvents(teamId);
        
        // Initialize JoinedEventsState for events the user has already joined
        final joinedEventsState = JoinedEventsState();
        final currentUserId = _eventsService.currentUserId;
        
        if (currentUserId != null) {
          for (Event event in teamEvents) {
            if (event.participants.contains(currentUserId)) {
              joinedEventsState.joinEvent(event.id);
              print('📊 Added team event to joined state: ${event.name} (${event.id})');
            }
          }
        }
        
        setState(() {
          _teamEvents = teamEvents;
        });
        
        print('✅ [Discovered Team] Loaded ${_teamEvents.length} team events');
        print('📊 JoinedEventsState initialized with: ${joinedEventsState.joinedEventIds}');
        
        // Log team events for debugging
        if (_teamEvents.isNotEmpty) {
          print('📋 [Discovered Team] Team Events loaded:');
          for (Event event in _teamEvents) {
            print('   - ${event.name} (${event.sportsDisplay})');
            print('     Start: ${event.startDate}');
            print('     Participants: ${event.participantCount}');
            print('     Is Team Event: ${event.id}');
            print('     User joined: ${event.participants.contains(currentUserId)}');
          }
        } else {
          print('📋 [Discovered Team] No team events found');
          
          // Debug: Check if there are any events in Firebase for this team
          print('🔍 [Discovered Team] Debugging: Checking all events in Firebase...');
          final allEvents = await _eventsService.getAllEventsForDebugging();
          final relatedEvents = allEvents.where((e) => 
            e['teamId'] == teamId || 
            e['businessId'] == teamId ||
            (e['isTeamEvent'] == true && e['businessName'] == widget.teamData['name'])
          ).toList();
          
          if (relatedEvents.isNotEmpty) {
            print('🔍 [Discovered Team] Found ${relatedEvents.length} potentially related events:');
            for (var event in relatedEvents) {
              print('   - ${event['name']} (ID: ${event['id']})');
              print('     Team ID: ${event['teamId']}');
              print('     Business ID: ${event['businessId']}');
              print('     Is Team Event: ${event['isTeamEvent']}');
            }
          } else {
            print('🔍 [Discovered Team] No related events found in Firebase for this team');
          }
        }
      } else {
        print('❌ [Discovered Team] Team ID is null, cannot load events');
      }
    } catch (e) {
      print('❌ [Discovered Team] Error loading team events: $e');
      setState(() {
        _teamEvents = [];
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
                  
                  // Member Count and Limit Info
                  FutureBuilder<int>(
                    future: _teamsService.getTeamMemberLimitForTeam(widget.teamData['id'] ?? ''),
                    builder: (context, snapshot) {
                      final memberCount = int.parse(widget.teamData['members'] ?? '1');
                      final limit = snapshot.data ?? 4;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$memberCount Member${memberCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (limit != -1) ...[
                                Text(
                                  ' / $limit',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (limit != -1 && memberCount >= limit) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Team is full',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (limit == -1) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Unlimited members (Premium)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Action Buttons Row - Horizontally Scrollable
            SizedBox(
              height: 110, // Increased height to accommodate text properly
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildScrollableActionButton(
                      icon: Icons.person_add,
                      label: isJoined ? 'Joined' : 'Join',
                      onTap: () async {
                        try {
                          final teamId = widget.teamData['id'];
                          if (teamId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Team ID not found'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          bool success;
                          String message;
                          if (isJoined) {
                            success = await _teamsService.leaveTeam(teamId);
                            message = success 
                                ? 'Left ${widget.teamData['name']}'
                                : 'Failed to leave ${widget.teamData['name']}';
                          } else {
                            final result = await _teamsService.joinTeamWithResult(teamId);
                            success = result['success'] as bool;
                            message = result['message'] as String;
                          }
                          
                          if (success) {
                            setState(() {
                              isJoined = !isJoined;
                            });
                            
                            // Reload team events after joining/leaving
                            await _loadTeamEvents();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildScrollableActionButton(
                      icon: Icons.people,
                      label: 'Member',
                      onTap: () async {
                        try {
                          // Fetch the actual team data from Firebase to get the members list
                          DocumentSnapshot teamDoc = await FirebaseFirestore.instance
                              .collection('teams')
                              .doc(widget.teamData['id'] ?? '')
                              .get();
                          
                          if (teamDoc.exists) {
                            Map<String, dynamic> teamData = teamDoc.data() as Map<String, dynamic>;
                            
                            // Create a Team object with actual member data
                            final team = Team(
                              id: widget.teamData['id'] ?? '',
                              name: widget.teamData['name'] ?? '',
                              description: widget.teamData['description'] ?? '',
                              createdBy: teamData['createdBy'] ?? widget.teamData['creator'] ?? '',
                              members: List<String>.from(teamData['members'] ?? []),
                              createdAt: teamData['createdAt']?.toDate() ?? DateTime.now(),
                            );
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeamMembersPage(teamData: team),
                              ),
                            );
                          } else {
                            print('❌ Team document not found');
                            // Fallback: show with empty members
                            final team = Team(
                              id: widget.teamData['id'] ?? '',
                              name: widget.teamData['name'] ?? '',
                              description: widget.teamData['description'] ?? '',
                              createdBy: widget.teamData['creator'] ?? '',
                              members: [],
                              createdAt: DateTime.now(),
                            );
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeamMembersPage(teamData: team),
                              ),
                            );
                          }
                        } catch (e) {
                          print('❌ Error fetching team data: $e');
                          // Fallback: show with empty members
                          final team = Team(
                            id: widget.teamData['id'] ?? '',
                            name: widget.teamData['name'] ?? '',
                            description: widget.teamData['description'] ?? '',
                            createdBy: widget.teamData['creator'] ?? '',
                            members: [],
                            createdAt: DateTime.now(),
                          );
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamMembersPage(teamData: team),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildScrollableActionButton(
                      icon: Icons.event,
                      label: 'Event',
                      onTap: () {
                        _showTeamEventsDialog();
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildScrollableActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share team coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildScrollableActionButton(
                      icon: Icons.info_outline,
                      label: 'Overview',
                      onTap: () {
                        _showTeamOverview();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Events Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _teamEvents.isEmpty ? 'No upcoming events' : 'Team Events (${_teamEvents.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (_teamEvents.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _showTeamEventsDialog();
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Event Cards or Placeholder
            if (_teamEvents.isEmpty) ...[
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
            ] else ...[
              // Display Team Events
              ...(_teamEvents.take(3).map((event) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildEventCard(event),
              )).toList()),
              
              // Show "View More" if there are more than 3 events
              if (_teamEvents.length > 3)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextButton(
                    onPressed: () {
                      _showTeamEventsDialog();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'View ${_teamEvents.length - 3} more events',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            
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

  Widget _buildScrollableActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100, // Fixed width for horizontal scrolling
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    radius: 20,
                    child: Icon(
                      icon,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Fixed height text container to prevent overflow
                  SizedBox(
                    height: 20,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
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
              Text('Events: ${_teamEvents.length}'),
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

  void _showTeamEventsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.event, color: Colors.orange),
              SizedBox(width: 8),
              Text('Team Events'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: _teamEvents.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This team hasn\'t created any events yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _teamEvents.length,
                    itemBuilder: (context, index) {
                      final event = _teamEvents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _getEventIcon(event.primarySport),
                          ),
                          title: Text(
                            event.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                event.dateRange,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${event.participantCount} participants',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: event.isUpcoming ? Colors.blue.withOpacity(0.1) : 
                                    event.isOngoing ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              event.isUpcoming ? 'Upcoming' : 
                              event.isOngoing ? 'Active' : 'Ended',
                              style: TextStyle(
                                fontSize: 10,
                                color: event.isUpcoming ? Colors.blue : 
                                       event.isOngoing ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
      size: 20,
      color: Colors.orange,
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        // Convert teamData map to Team object for navigation
        final teamObject = Team(
          id: widget.teamData['id'] ?? '',
          name: widget.teamData['name'] ?? '',
          description: widget.teamData['description'] ?? '',
          members: [], // Empty list since we don't have member details
          createdBy: '',
          createdAt: DateTime.now(),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamEventDetailsPage(
              event: event,
              team: teamObject,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header with Tap Hint
            const Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: Colors.orange,
                ),
                SizedBox(width: 4),
                Text(
                  'Tap for details',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _getEventIcon(event.primarySport),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.dateRange,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: event.isUpcoming ? Colors.blue.withOpacity(0.1) : 
                          event.isOngoing ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.isUpcoming ? 'Upcoming' : 
                    event.isOngoing ? 'Active' : 'Ended',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: event.isUpcoming ? Colors.blue : 
                             event.isOngoing ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${event.participantCount} participants',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  event.sportsDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Join/Leave Button - prevent tap from propagating to parent
            GestureDetector(
              onTap: () => _handleEventJoinLeave(event),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: event.isActive ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      event.isActive ? Icons.check : Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.isActive ? 'Joined' : 'Join Event',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
