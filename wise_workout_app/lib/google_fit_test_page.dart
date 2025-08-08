import 'package:flutter/material.dart';
import 'package:wise_workout_app/services/google_fit_service.dart';

class GoogleFitTestPage extends StatefulWidget {
  const GoogleFitTestPage({super.key});

  @override
  State<GoogleFitTestPage> createState() => _GoogleFitTestPageState();
}

class _GoogleFitTestPageState extends State<GoogleFitTestPage> {
  final GoogleFitService _googleFitService = GoogleFitService();
  String _status = 'Not tested yet';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    await _googleFitService.initialize();
    setState(() {
      _status = _googleFitService.isSignedIn 
          ? 'Already connected to Google Fit' 
          : 'Not connected to Google Fit';
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      print('🚀 Starting Google Fit connection test');
      final bool success = await _googleFitService.connectToGoogleFit();
      
      setState(() {
        _isLoading = false;
        if (success) {
          _status = '✅ SUCCESS: Connected to Google Fit!';
        } else {
          _status = '❌ FAILED: Could not connect to Google Fit\n\nPossible issues:\n• Fitness API not enabled in Google Cloud Console\n• OAuth client not configured properly\n• Missing scopes/permissions\n\nCheck the console logs for details.';
        }
      });

      // If connected, try to get some data
      if (success) {
        setState(() {
          _status += '\n\n📊 Fetching comprehensive fitness data...';
        });

        final stepCount = await _googleFitService.getTodayStepCount();
        final calories = await _googleFitService.getTodayCalories();
        final distance = await _googleFitService.getTodayDistance();
        final moveMinutes = await _googleFitService.getTodayMoveMinutes();
        final heartRate = await _googleFitService.getTodayAverageHeartRate();
        
        setState(() {
          _status = '✅ SUCCESS: Connected to Google Fit!\n\n📊 Today\'s Fitness Data:\n'
              '• Steps: ${stepCount ?? 'No data'}\n'
              '• Calories: ${calories?.toStringAsFixed(1) ?? 'No data'} kcal\n'
              '• Distance: ${distance != null ? '${(distance / 1000).toStringAsFixed(2)} km' : 'No data'}\n'
              '• Move Minutes: ${moveMinutes ?? 'No data'} min\n'
              '• Avg Heart Rate: ${heartRate?.toStringAsFixed(0) ?? 'No data'} bpm';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ ERROR: $e\n\nCheck the console logs for more details.';
      });
      print('🔥 Exception in test: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Fit Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Google Fit Connection Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Test Google Fit Connection',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Instructions:\n\n1. Tap "Test Google Fit Connection"\n2. Sign in with your Google account\n3. Grant fitness permissions\n4. Check if fitness data is retrieved:\n   • Step count\n   • Calories burned\n   • Distance traveled\n   • Move minutes\n   • Average heart rate',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
