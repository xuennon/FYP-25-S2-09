import 'package:flutter/material.dart';
import '../services/firebase_subscription_service.dart';

class SubscriptionStatusWidget extends StatefulWidget {
  const SubscriptionStatusWidget({super.key});

  @override
  State<SubscriptionStatusWidget> createState() => _SubscriptionStatusWidgetState();
}

class _SubscriptionStatusWidgetState extends State<SubscriptionStatusWidget> {
  final FirebaseSubscriptionService _subscriptionService = FirebaseSubscriptionService();
  String _userType = 'normal';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      String userType = await _subscriptionService.getUserSubscriptionType();
      if (mounted) {
        setState(() {
          _userType = userType;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading subscription status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _userType == 'premium' ? Colors.orange : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _userType == 'premium' ? 'PREMIUM' : 'FREE',
        style: TextStyle(
          color: _userType == 'premium' ? Colors.white : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Helper class for subscription checks throughout the app
class SubscriptionHelper {
  static final FirebaseSubscriptionService _subscriptionService = FirebaseSubscriptionService();

  // Check if user has premium access to a feature
  static Future<bool> hasFeatureAccess(String feature) async {
    bool isPremium = await _subscriptionService.hasPremiumSubscription();
    
    // Define which features require premium
    const premiumFeatures = [
      'personalized_training',
      'nutrition_planning',
      'advanced_analytics',
      'unlimited_workouts',
      'priority_support',
    ];

    // If it's a premium feature and user doesn't have premium, deny access
    if (premiumFeatures.contains(feature) && !isPremium) {
      return false;
    }

    return true;
  }

  // Show upgrade dialog for premium features
  static Future<void> showUpgradeDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Premium Feature'),
          content: const Text(
            'This feature requires a Premium subscription. Would you like to upgrade?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription page
                Navigator.of(context).pushNamed('/subscription');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
