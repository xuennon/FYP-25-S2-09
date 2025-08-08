import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTeamsPage extends StatefulWidget {
  final String username;
  final String userId;
  
  const UserTeamsPage({
    super.key, 
    required this.username,
    required this.userId,
  });

  @override
  State<UserTeamsPage> createState() => _UserTeamsPageState();
}

class _UserTeamsPageState extends State<UserTeamsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _userTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserTeams();
  }

  Future<void> _loadUserTeams() async {
    print('🔄 Loading teams for user: ${widget.userId}');
    print('🔄 Username: ${widget.username}');
    try {
      setState(() {
        _isLoading = true;
      });

      // First, let's see all teams in the database
      print('🔍 First checking all teams in database...');
      QuerySnapshot allTeamsSnapshot = await _firestore
          .collection('teams')
          .get();
      
      print('📊 Total teams in database: ${allTeamsSnapshot.docs.length}');
      for (var doc in allTeamsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> members = data['members'] ?? [];
        print('🏆 Team: ${data['name']}, Members: $members, CreatedBy: ${data['createdBy']}');
        
        // Check if this user is in the members array
        if (members.contains(widget.userId)) {
          print('✅ User ${widget.userId} IS a member of team ${data['name']}');
        } else {
          print('❌ User ${widget.userId} is NOT a member of team ${data['name']}');
        }
      }

      // Get teams where this user is a member (including created and joined teams)
      print('🔍 Querying teams where user ${widget.userId} is a member...');
      QuerySnapshot querySnapshot = await _firestore
          .collection('teams')
          .where('members', arrayContains: widget.userId)
          .get();

      print('📊 Found ${querySnapshot.docs.length} teams for user ${widget.userId}');

      List<Map<String, dynamic>> teams = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        teams.add(data);
        print('🏆 Team found: ${data['name']} (ID: ${doc.id})');
      }

      setState(() {
        _userTeams = teams;
        _isLoading = false;
      });
      
      print('✅ Successfully loaded ${teams.length} teams for user ${widget.userId}');
    } catch (e) {
      print('❌ Error loading user teams: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTeams() async {
    await _loadUserTeams();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
          '${widget.username}\'s Teams',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTeams,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : _userTeams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No teams yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.username} hasn\'t created any teams yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _userTeams.length,
                    itemBuilder: (context, index) {
                      final team = _userTeams[index];
                      return _buildTeamCard(team);
                    },
                  ),
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team['name'] ?? 'Unnamed Team',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Created ${_formatTimestamp(team['createdAt'] as Timestamp?)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (team['description'] != null && team['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                team['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Team Stats
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${(team['members'] as List?)?.length ?? 1} member${((team['members'] as List?)?.length ?? 1) == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.sports_soccer,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  team['activityType'] ?? 'General',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Created',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
