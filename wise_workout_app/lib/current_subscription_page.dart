import 'package:flutter/material.dart';
import 'services/firebase_subscription_service.dart';

class CurrentSubscriptionPage extends StatefulWidget {
  const CurrentSubscriptionPage({super.key});

  @override
  State<CurrentSubscriptionPage> createState() => _CurrentSubscriptionPageState();
}

class _CurrentSubscriptionPageState extends State<CurrentSubscriptionPage> {
  final FirebaseSubscriptionService _subscriptionService = FirebaseSubscriptionService();
  String currentUserType = 'normal';
  bool isLoadingSubscription = true;
  bool _isProcessing = false;

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
          'Current Subscription',
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
              // Current Plan Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      currentUserType == 'premium' ? 'Premium' : 'Free',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currentUserType == 'premium' ? '\$3.90' : '\$0.00',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
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
                    if (currentUserType == 'premium') ...[
                      _buildFeatureItem('✓ All free features', Colors.white),
                      _buildFeatureItem('✓ Personalized fitness plans', Colors.white),
                      _buildFeatureItem('✓ Unlimited program subscription', Colors.white),
                      _buildFeatureItem('✓ Unlimited team member', Colors.white),
                      _buildFeatureItem('✓ Analytics', Colors.white),
                    ] else ...[
                      _buildFeatureItem('✓ Access to basic workouts', Colors.white),
                      _buildFeatureItem('✓ Limited exercise tracking', Colors.white),
                      _buildFeatureItem('✓ Daily reminders', Colors.white),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.orange, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'In Use',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cancel Subscription Button (only show for premium users)
              if (currentUserType == 'premium')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: _isProcessing ? null : () {
                      _showCancelSubscriptionDialog();
                    },
                    child: Text(
                      _isProcessing ? 'Processing...' : 'Cancel Subscription',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  void _showCancelSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Subscription'),
          content: const Text(
            'Are you sure you want to cancel your Premium subscription? You will lose access to premium features.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Keep Subscription'),
            ),
            ElevatedButton(
              onPressed: _isProcessing ? null : () async {
                setState(() {
                  _isProcessing = true;
                });

                Navigator.of(context).pop();

                try {
                  bool success = await _subscriptionService.activateFreeSubscription();
                  
                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Subscription cancelled successfully. You are now on the Free plan.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      await _loadCurrentSubscription();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to cancel subscription. Please try again.'),
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
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
                      'Cancel Subscription',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        );
      },
    );
  }
}
