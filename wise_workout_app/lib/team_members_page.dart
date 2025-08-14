import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/team.dart';

class TeamMembersPage extends StatefulWidget {
  final Team teamData;
  
  const TeamMembersPage({super.key, required this.teamData});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _memberData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMemberData();
  }

  Future<void> _fetchMemberData() async {
    try {
      List<Map<String, dynamic>> members = [];
      
      // Debug: Print team data info
      print('🔍 TeamMembersPage Debug:');
      print('Team ID: ${widget.teamData.id}');
      print('Team Name: ${widget.teamData.name}');
      print('Team Members List: ${widget.teamData.members}');
      print('Members Count: ${widget.teamData.members.length}');
      print('Created By: ${widget.teamData.createdBy}');
      
      // If members list is empty, try to fetch fresh team data from Firebase
      List<String> membersList = widget.teamData.members;
      if (membersList.isEmpty) {
        print('⚠️ Members list is empty, fetching fresh team data from Firebase...');
        try {
          DocumentSnapshot teamDoc = await FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamData.id)
              .get();
              
          if (teamDoc.exists) {
            Map<String, dynamic> teamData = teamDoc.data() as Map<String, dynamic>;
            membersList = List<String>.from(teamData['members'] ?? []);
            print('✅ Fresh team data fetched. Members: $membersList');
          } else {
            print('❌ Team document not found in Firebase');
          }
        } catch (e) {
          print('❌ Error fetching fresh team data: $e');
        }
      }
      
      // Fetch data for each member
      for (String memberId in membersList) {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();
          
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            members.add({
              'userId': memberId,
              'username': userData['username'] ?? userData['displayName'] ?? 'Unknown User',
              'email': userData['email'] ?? '',
              'isOwner': memberId == widget.teamData.createdBy,
              'isAdmin': memberId == widget.teamData.createdBy, // For now, only owner is admin
            });
          } else {
            // Handle case where user document doesn't exist
            members.add({
              'userId': memberId,
              'username': 'Unknown User',
              'email': '',
              'isOwner': memberId == widget.teamData.createdBy,
              'isAdmin': memberId == widget.teamData.createdBy,
            });
          }
        } catch (e) {
          print('Error fetching data for member $memberId: $e');
          // Add placeholder data for this member
          members.add({
            'userId': memberId,
            'username': 'User $memberId',
            'email': '',
            'isOwner': memberId == widget.teamData.createdBy,
            'isAdmin': memberId == widget.teamData.createdBy,
          });
        }
      }
      
      // Sort members: owner first, then others
      members.sort((a, b) {
        if (a['isOwner'] && !b['isOwner']) return -1;
        if (!a['isOwner'] && b['isOwner']) return 1;
        return 0;
      });
      
      setState(() {
        _memberData = members;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching member data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(
          'Team Members (${widget.teamData.members.length})',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.orange,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: 'EVERYONE'),
                      Tab(text: 'ADMINS'),
                    ],
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Everyone Tab
                      _buildMembersTab(showAll: true),
                      
                      // Admins Tab
                      _buildMembersTab(showAll: false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMembersTab({required bool showAll}) {
    // Filter members based on tab
    List<Map<String, dynamic>> filteredMembers;
    if (showAll) {
      filteredMembers = _memberData;
    } else {
      filteredMembers = _memberData.where((member) => member['isAdmin'] == true).toList();
    }

    if (filteredMembers.isEmpty) {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Text(
            showAll ? 'No members found' : 'No admins found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text(
              showAll ? 'MEMBERS (${filteredMembers.length})' : 'ADMINS (${filteredMembers.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Members List
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  return _buildMemberItem(
                    name: member['username'],
                    isOwner: member['isOwner'],
                    isAdmin: member['isAdmin'],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem({
    required String name,
    required bool isOwner,
    required bool isAdmin,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isOwner ? Colors.orange : Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Name and Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Owner',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ] else if (isAdmin) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Admin badge or actions
          if (isOwner || isAdmin) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOwner ? Colors.orange[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOwner ? 'OWNER' : 'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isOwner ? Colors.orange[700] : Colors.blue[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
