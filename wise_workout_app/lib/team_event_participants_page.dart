import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/event.dart';
import 'models/team.dart';

class TeamEventParticipantsPage extends StatefulWidget {
  final Event event;
  final Team teamData;
  
  const TeamEventParticipantsPage({
    super.key, 
    required this.event,
    required this.teamData,
  });

  @override
  State<TeamEventParticipantsPage> createState() => _TeamEventParticipantsPageState();
}

class _TeamEventParticipantsPageState extends State<TeamEventParticipantsPage> {
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('🔄 Loading participants for event: ${widget.event.name}');
      print('📋 Participant IDs: ${widget.event.participants}');
      
      List<Map<String, dynamic>> participantDetails = [];
      
      if (widget.event.participants.isNotEmpty) {
        // Get participant details from users collection
        for (String participantId in widget.event.participants) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(participantId)
                .get();
                
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              participantDetails.add({
                'id': participantId,
                'name': userData['name'] ?? userData['username'] ?? 'Unknown User',
                'username': userData['username'] ?? userData['name'] ?? 'unknown',
                'email': userData['email'] ?? '',
                'profileImage': userData['profileImage'] ?? userData['profileImageUrl'] ?? '',
                'joinedAt': userData['createdAt'] ?? Timestamp.now(),
              });
              print('✅ Loaded user: ${userData['name'] ?? userData['username'] ?? 'Unknown'}');
            } else {
              // If user document doesn't exist, create a placeholder
              participantDetails.add({
                'id': participantId,
                'name': 'User $participantId',
                'username': 'user_${participantId.substring(0, 8)}',
                'email': '',
                'profileImage': '',
                'joinedAt': Timestamp.now(),
              });
              print('⚠️ User document not found for ID: $participantId');
            }
          } catch (e) {
            print('❌ Error loading participant $participantId: $e');
            // Add error placeholder
            participantDetails.add({
              'id': participantId,
              'name': 'Error Loading User',
              'username': 'error_user',
              'email': '',
              'profileImage': '',
              'joinedAt': Timestamp.now(),
            });
          }
        }
        
        // Sort participants by name
        participantDetails.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      }
      
      setState(() {
        _participants = participantDetails;
        _isLoading = false;
      });
      
      print('✅ Loaded ${_participants.length} participants for event: ${widget.event.name}');
      
    } catch (e) {
      print('❌ Error loading participants: $e');
      setState(() {
        _participants = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Participants',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.event.name,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_participants.length} ${_participants.length == 1 ? 'Member' : 'Members'}',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            )
          : _participants.isEmpty
              ? _buildEmptyState()
              : _buildParticipantsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.people_outline,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Participants Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This event doesn\'t have any participants yet. Team members can join the event from the team details page.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    return RefreshIndicator(
      onRefresh: _loadParticipants,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final participant = _participants[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildParticipantCard(participant, index),
          );
        },
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant, int index) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Participant Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  backgroundImage: participant['profileImage'] != null && 
                                   participant['profileImage'].toString().isNotEmpty
                      ? NetworkImage(participant['profileImage'])
                      : null,
                  child: participant['profileImage'] == null || 
                          participant['profileImage'].toString().isEmpty
                      ? Text(
                          _getInitials(participant['name']),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Position indicator for first 3 participants
                if (index < 3)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: index == 0 ? const Color(0xFFFFD700) : 
                               index == 1 ? Colors.grey[400] : 
                               Colors.brown[300],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Participant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          participant['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (index == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'First to Join',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${participant['username']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (participant['email'].toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      participant['email'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Join date info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  _formatJoinDate(participant['joinedAt']),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
    }
  }

  String _formatJoinDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else {
        return '${(difference.inDays / 30).floor()}m ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}
