import 'package:flutter/material.dart';
import 'services/firebase_admin_service.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final FirebaseAdminService _adminService = FirebaseAdminService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _users = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  bool _showSuspendedOnly = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    bool isAdmin = await _adminService.isCurrentUserAdmin();
    if (!isAdmin) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, int> stats = await _adminService.getUserStatistics();
      List<Map<String, dynamic>> users;
      
      if (_showSuspendedOnly) {
        users = await _adminService.getSuspendedUsers();
      } else {
        users = await _adminService.getAllUsers();
      }

      setState(() {
        _statistics = stats;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _loadData();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> users = await _adminService.searchUsers(searchTerm);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserSuspension(String userId, bool isSuspended) async {
    try {
      bool success;
      if (isSuspended) {
        success = await _adminService.unsuspendUser(userId);
      } else {
        success = await _adminService.suspendUser(userId);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuspended ? 'User unsuspended successfully' : 'User suspended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update user status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Statistics Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Total Users', _statistics['total'] ?? 0, Colors.blue),
                _buildStatCard('Active', _statistics['active'] ?? 0, Colors.green),
                _buildStatCard('Suspended', _statistics['suspended'] ?? 0, Colors.red),
              ],
            ),
          ),

          // Search and Filter Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by username or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _searchUsers,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('Show Suspended Only'),
                        selected: _showSuspendedOnly,
                        onSelected: (selected) {
                          setState(() {
                            _showSuspendedOnly = selected;
                          });
                          _loadData();
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _showSuspendedOnly = false;
                        });
                        _loadData();
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isSuspended = user['suspensionStatus'] == 'yes';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: isSuspended 
                                  ? Border.all(color: Colors.red.withOpacity(0.3))
                                  : null,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSuspended ? Colors.red : Colors.green,
                                child: Text(
                                  (user['username'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user['username'] ?? 'Unknown User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSuspended ? Colors.red : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['email'] ?? 'No email'),
                                  Text(
                                    'Status: ${isSuspended ? "Suspended" : "Active"}',
                                    style: TextStyle(
                                      color: isSuspended ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _toggleUserSuspension(
                                  user['docId'],
                                  isSuspended,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSuspended ? Colors.green : Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(isSuspended ? 'Unsuspend' : 'Suspend'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
