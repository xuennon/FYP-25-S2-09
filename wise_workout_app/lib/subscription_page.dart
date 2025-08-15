import 'package:flutter/material.dart';
import 'services/firebase_subscription_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final FirebaseSubscriptionService _subscriptionService = FirebaseSubscriptionService();
  bool _isProcessing = false;
  String currentUserType = 'normal';
  bool isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      String userType = await _subscriptionService.getUserSubscriptionType();
      setState(() {
        currentUserType = userType;
        isLoadingSubscription = false;
      });
    } catch (e) {
      setState(() {
        currentUserType = 'normal';
        isLoadingSubscription = false;
      });
    }
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
        title: const Text(
          'Subscription',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
            // Free Plan Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: '\$0.00',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '/month',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem('✓ Access to basic workouts', Colors.white),
                  _buildFeatureItem('✓ Limited exercise tracking', Colors.white),
                  _buildFeatureItem('✓ Daily reminders', Colors.white),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: currentUserType == 'normal' ? null : () {
                        _handleSubscription('free');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentUserType == 'normal' ? Colors.grey : Colors.orange,
                        side: currentUserType == 'normal' ? const BorderSide(color: Colors.orange, width: 2) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isLoadingSubscription ? 'Loading...' : (currentUserType == 'normal' ? 'In Use' : 'Select'),
                        style: TextStyle(
                          color: currentUserType == 'normal' ? Colors.orange : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Premium Plan Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: '\$3.90',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '/month',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem('✓ All free features', Colors.white),
                  _buildFeatureItem('✓ Personalized fitness plans', Colors.white),
                  _buildFeatureItem('✓ Unlimited program subscription', Colors.white),
                  _buildFeatureItem('✓ Unlimited team member', Colors.white),
                  _buildFeatureItem('✓ Analytics', Colors.white),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: currentUserType == 'premium' ? null : () {
                        _handleSubscription('premium');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentUserType == 'premium' ? Colors.grey : Colors.orange,
                        side: currentUserType == 'premium' ? const BorderSide(color: Colors.orange, width: 2) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isLoadingSubscription ? 'Loading...' : (currentUserType == 'premium' ? 'In Use' : 'Get Premium'),
                        style: TextStyle(
                          color: currentUserType == 'premium' ? Colors.orange : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscription(String planType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Subscribe to ${planType == 'free' ? 'Free' : 'Premium'} Plan'),
          content: Text(
            planType == 'free'
              ? 'You are selecting the Free plan for \$0.00/month. This includes basic workouts and limited features.'
              : 'You are selecting the Premium plan for \$3.90/month. This includes all features and personalized fitness plans.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isProcessing ? null : () async {
                // Set processing state
                setState(() {
                  _isProcessing = true;
                });

                Navigator.of(context).pop(); // Close dialog first

                try {
                  bool success = false;
                  if (planType == 'free') {
                    success = await _subscriptionService.activateFreeSubscription();
                  } else {
                    success = await _subscriptionService.activatePremiumSubscription();
                  }

                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${planType == 'free' ? 'Free' : 'Premium'} subscription activated successfully!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      // Refresh the current subscription status
                      await _loadCurrentSubscription();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to activate subscription. Please try again.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } finally {
                  // Reset processing state
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: planType == 'free' ? Colors.orange : Colors.orange,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Subscribe',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        );
      },
    );
  }
}
