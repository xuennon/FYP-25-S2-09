import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_feedback_service.dart';
import '../services/testimonial_migration_service.dart';

class TestimonialManagementPage extends StatefulWidget {
  const TestimonialManagementPage({super.key});

  @override
  State<TestimonialManagementPage> createState() => _TestimonialManagementPageState();
}

class _TestimonialManagementPageState extends State<TestimonialManagementPage> with TickerProviderStateMixin {
  final FirebaseFeedbackService _feedbackService = FirebaseFeedbackService();
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      Map<String, dynamic> stats = await _feedbackService.getFeedbackStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _runMigration() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Running Migration'),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Migrating testimonials...'),
          ],
        ),
      ),
    );

    try {
      await TestimonialMigrationService.migrateExistingTestimonials();
      await _loadStats(); // Reload stats after migration
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Migration completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testimonial Management'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Premium'),
            Tab(text: 'Stats'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _runMigration,
            tooltip: 'Run Migration',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTestimonials(),
          _buildCompletedTestimonials(),
          _buildPremiumTestimonials(),
          _buildStatsPage(),
        ],
      ),
    );
  }

  Widget _buildAllTestimonials() {
    return StreamBuilder<QuerySnapshot>(
      stream: _feedbackService.getAllFeedback(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No testimonials found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildTestimonialCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildCompletedTestimonials() {
    return StreamBuilder<QuerySnapshot>(
      stream: _feedbackService.getFeedbackByCompletion(true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No completed testimonials found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildTestimonialCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildPremiumTestimonials() {
    return StreamBuilder<QuerySnapshot>(
      stream: _feedbackService.getCompletedPremiumFeedback(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No premium testimonials found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildTestimonialCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildStatsPage() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Testimonial Statistics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Total Testimonials', _stats['total']?.toString() ?? '0'),
                  _buildStatRow('Completed', _stats['completed']?.toString() ?? '0'),
                  _buildStatRow('Incomplete', _stats['incomplete']?.toString() ?? '0'),
                  const Divider(),
                  _buildStatRow('Premium Users', _stats['premiumUsers']?.toString() ?? '0'),
                  _buildStatRow('Normal Users', _stats['normalUsers']?.toString() ?? '0'),
                  const Divider(),
                  _buildStatRow('Average Rating', '${(_stats['averageRating'] ?? 0.0).toStringAsFixed(1)} ⭐'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(String docId, Map<String, dynamic> data) {
    bool isCompleted = data['isCompleted'] ?? false;
    String userType = data['userType'] ?? 'normal';
    int rating = data['rating'] ?? 0;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Completion status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'COMPLETED' : 'INCOMPLETE',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // User type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: userType == 'premium' ? Colors.purple : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userType.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const Spacer(),
                // Rating
                Row(
                  children: [
                    Text('$rating'),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['feedback'] ?? 'No feedback provided',
              style: const TextStyle(fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (data['name'] != null) ...[
              const SizedBox(height: 4),
              Text('Name: ${data['name']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
            if (data['email'] != null) ...[
              const SizedBox(height: 2),
              Text('Email: ${data['email']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}
