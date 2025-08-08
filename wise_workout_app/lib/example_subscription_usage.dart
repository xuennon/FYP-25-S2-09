// Example: How to use the subscription system in your app

import 'package:flutter/material.dart';
import 'services/firebase_subscription_service.dart';
import 'widgets/subscription_status_widget.dart';

class ExampleUsagePage extends StatefulWidget {
  const ExampleUsagePage({super.key});

  @override
  State<ExampleUsagePage> createState() => _ExampleUsagePageState();
}

class _ExampleUsagePageState extends State<ExampleUsagePage> {
  final FirebaseSubscriptionService _subscriptionService = FirebaseSubscriptionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Feature Example'),
        actions: const [
          // Show subscription status in app bar
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SubscriptionStatusWidget(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Example 1: Check subscription status and show different content
            FutureBuilder<bool>(
              future: _subscriptionService.hasPremiumSubscription(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                bool isPremium = snapshot.data ?? false;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          isPremium ? 'Premium Content' : 'Free Content',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPremium
                              ? 'Welcome to premium! You have access to all features.'
                              : 'You are using the free version. Upgrade for more features!',
                        ),
                        if (!isPremium) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/subscription');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text(
                              'Upgrade to Premium',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Example 2: Premium feature with access check
            ElevatedButton(
              onPressed: () => _accessPremiumFeature(),
              child: const Text('Access Premium Feature'),
            ),

            const SizedBox(height: 20),

            // Example 3: Show current subscription details
            FutureBuilder<Map<String, dynamic>>(
              future: _subscriptionService.getSubscriptionDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                Map<String, dynamic> details = snapshot.data ?? {};

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subscription Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Type: ${details['userType'] ?? 'Unknown'}'),
                        Text('Active: ${details['isActive'] ?? false}'),
                        if (details['subscriptionUpdatedAt'] != null)
                          Text('Last Updated: ${details['subscriptionUpdatedAt']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Example method for accessing premium features
  Future<void> _accessPremiumFeature() async {
    bool hasPremium = await _subscriptionService.hasPremiumSubscription();
    
    if (hasPremium) {
      // User has premium - show premium feature
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Premium Feature'),
          content: const Text('This is a premium-only feature! You have access because you are a premium user.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // User doesn't have premium - show upgrade dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Premium Required'),
          content: const Text('This feature requires a Premium subscription. Would you like to upgrade?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/subscription');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Upgrade', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }
}
