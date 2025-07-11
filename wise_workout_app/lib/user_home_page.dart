import 'package:flutter/material.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
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

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Profile and Search
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                child: Icon(Icons.person),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
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
                  // TODO: Implement settings
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home, color: Colors.grey[600], size: 28),
              const Text(
                'Home',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, color: Colors.grey[600], size: 28),
              const Text(
                'Friend',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, color: Colors.grey[600], size: 28),
              const Text(
                'Event',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, color: Colors.grey[600], size: 28),
              const Text(
                'Profile',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileSection(),
            Expanded(
              child: Container(
                // Empty container that can be used for future content
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(20),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }
}
