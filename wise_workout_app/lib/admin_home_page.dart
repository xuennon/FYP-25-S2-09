import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  void _handleMenuOption(BuildContext context, String option) {
    switch (option) {
      case 'Profile':
        // TODO: Navigate to profile page
        break;
      case 'Settings':
        // TODO: Navigate to settings page
        break;
      case 'Landing Page':
        // TODO: Navigate to landing page
        break;
      case 'Categories':
        // TODO: Navigate to categories page
        break;
      case 'Logs':
        // TODO: Navigate to logs page
        break;
      case 'Logout':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Logout Confirmation'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        );
        break;
    }
  }

  Widget _buildInfoCard(String title, String value, {bool isRed = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isRed ? Colors.red : Colors.black,
                ),
              ),
              if (isRed) ...[
                const SizedBox(width: 4),
                const Icon(Icons.circle, color: Colors.red, size: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: 8),
            Text('Admin'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              // TODO: Handle messages
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String choice) => _handleMenuOption(context, choice),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.grey[800]),
                      const SizedBox(width: 8),
                      const Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, color: Colors.grey[800]),
                      const SizedBox(width: 8),
                      const Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Landing Page',
                  child: Row(
                    children: [
                      Icon(Icons.web_outlined, color: Colors.grey[800]),
                      const SizedBox(width: 8),
                      const Text('Landing Page'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Categories',
                  child: Row(
                    children: [
                      Icon(Icons.category_outlined, color: Colors.grey[800]),
                      const SizedBox(width: 8),
                      const Text('Categories'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Logs',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, color: Colors.grey[800]),
                      const SizedBox(width: 8),
                      const Text('Logs'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.grey[800]),
                      const SizedBox(width: 8),
                      const Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInfoCard('Total Users', '1234'),
                _buildInfoCard('Suspended\nAccount', '3'),
                _buildInfoCard('Pending\nApplications', '5', isRed: true),
                _buildInfoCard('Feedback', '12'),
              ],
            ),
            const SizedBox(height: 24),
            _buildActionButton('Manage User Account', Icons.people),
            const SizedBox(height: 16),
            _buildActionButton('Manage Business\nAccount', Icons.business),
            const SizedBox(height: 16),
            _buildActionButton('Reports', Icons.bar_chart),
          ],
        ),
      ),
    );
  }
}
