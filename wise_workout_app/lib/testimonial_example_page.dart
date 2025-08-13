// Example: How to use the updated testimonial/feedback system with new fields

import 'package:flutter/material.dart';
import 'services/firebase_feedback_service.dart';
import 'services/testimonial_migration_service.dart';

class TestimonialExample extends StatefulWidget {
  const TestimonialExample({super.key});

  @override
  State<TestimonialExample> createState() => _TestimonialExampleState();
}

class _TestimonialExampleState extends State<TestimonialExample> {
  final FirebaseFeedbackService _feedbackService = FirebaseFeedbackService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testimonial System Example'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Testimonial Statistics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _feedbackService.getFeedbackStats(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        Map<String, dynamic> stats = snapshot.data ?? {};

                        return Column(
                          children: [
                            _buildStatRow('Total', stats['total']?.toString() ?? '0'),
                            _buildStatRow('Completed', stats['completed']?.toString() ?? '0'),
                            _buildStatRow('Premium Users', stats['premiumUsers']?.toString() ?? '0'),
                            _buildStatRow('Average Rating', '${(stats['averageRating'] ?? 0.0).toStringAsFixed(1)} ⭐'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Migration Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runMigration,
                icon: const Icon(Icons.upgrade),
                label: const Text('Run Migration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Check Status Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkMigrationStatus,
                icon: const Icon(Icons.info),
                label: const Text('Check Migration Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recent Testimonials Section
            const Text(
              'Recent Completed Testimonials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Recent testimonials list
            Expanded(
              child: StreamBuilder(
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
                      return _buildTestimonialCard(data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(Map<String, dynamic> data) {
    String userType = data['userType'] ?? 'normal';
    bool isCompleted = data['isCompleted'] ?? false;
    int rating = data['rating'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: userType == 'premium' ? Colors.orange : Colors.grey,
          child: Text(
            userType == 'premium' ? 'P' : 'F',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          data['feedback'] ?? 'No feedback',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$rating ⭐'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Incomplete',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: userType == 'premium' ? Colors.purple : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    userType.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            if (data['name'] != null)
              Text('by ${data['name']}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
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

  Future<void> _checkMigrationStatus() async {
    try {
      Map<String, int> status = await TestimonialMigrationService.checkTestimonialMigrationStatus();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Migration Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total testimonials: ${status['total']}'),
                Text('With isCompleted: ${status['withIsCompleted']}'),
                Text('With userType: ${status['withUserType']}'),
                Text('Completed: ${status['completed']}'),
                Text('Premium users: ${status['premium']}'),
                Text('Normal users: ${status['normal']}'),
                const Divider(),
                Text('Need isCompleted migration: ${status['needsIsCompletedMigration']}'),
                Text('Need userType migration: ${status['needsUserTypeMigration']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
