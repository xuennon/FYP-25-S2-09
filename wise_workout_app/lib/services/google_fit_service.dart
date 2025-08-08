import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleFitService {
  // Google Fit API scopes
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/fitness.activity.read',
    'https://www.googleapis.com/auth/fitness.body.read',
    'https://www.googleapis.com/auth/fitness.location.read',
    'https://www.googleapis.com/auth/fitness.nutrition.read',
    'https://www.googleapis.com/auth/fitness.heart_rate.read',
  ];

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  // Singleton pattern
  static final GoogleFitService _instance = GoogleFitService._internal();
  factory GoogleFitService() => _instance;
  GoogleFitService._internal();

  GoogleSignInAccount? _currentUser;

  // Check if user is already signed in
  bool get isSignedIn => _currentUser != null;

  // Get current user
  GoogleSignInAccount? get currentUser => _currentUser;

  // Initialize and check existing sign-in
  Future<void> initialize() async {
    _currentUser = await _googleSignIn.signInSilently();
  }

  // Connect to Google Fit
  Future<bool> connectToGoogleFit() async {
    try {
      print('🔍 Starting Google Fit connection...');
      
      // Sign in to Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        // User cancelled the sign-in
        print('❌ User cancelled Google Sign-In');
        return false;
      }

      print('✅ Google Sign-In successful: ${account.email}');
      _currentUser = account;

      // Get authentication headers
      final authHeaders = await account.authHeaders;
      print('✅ Got auth headers: ${authHeaders.keys}');
      
      // Test the connection by making a simple API call
      final bool isConnected = await _testConnection(authHeaders);
      print('🧪 Connection test result: $isConnected');
      
      return isConnected;
    } catch (error) {
      print('❌ Error connecting to Google Fit: $error');
      print('📊 Error type: ${error.runtimeType}');
      return false;
    }
  }

  // Disconnect from Google Fit
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (error) {
      print('Error disconnecting from Google Fit: $error');
    }
  }

  // Test the connection by fetching user's data sources
  Future<bool> _testConnection(Map<String, String> authHeaders) async {
    try {
      print('🧪 Testing Google Fit API connection...');
      const String url = 'https://www.googleapis.com/fitness/v1/users/me/dataSources';
      
      print('📡 Making request to: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: authHeaders,
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Google Fit API connection successful!');
        return true;
      } else {
        print('❌ Google Fit API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (error) {
      print('❌ Error testing Google Fit connection: $error');
      print('📊 Error type: ${error.runtimeType}');
      return false;
    }
  }

  // Get step count for today
  Future<int?> getTodayStepCount() async {
    if (_currentUser == null) return null;

    try {
      final authHeaders = await _currentUser!.authHeaders;
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      const String dataTypeName = 'com.google.step_count.delta';
      const String url = 'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate';

      final requestBody = {
        'aggregateBy': [
          {
            'dataTypeName': dataTypeName,
          }
        ],
        'bucketByTime': {'durationMillis': 86400000}, // 24 hours
        'startTimeMillis': startOfDay.millisecondsSinceEpoch,
        'endTimeMillis': endOfDay.millisecondsSinceEpoch,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...authHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final buckets = data['bucket'] as List?;
        
        if (buckets != null && buckets.isNotEmpty) {
          final datasets = buckets[0]['dataset'] as List?;
          if (datasets != null && datasets.isNotEmpty) {
            final points = datasets[0]['point'] as List?;
            if (points != null && points.isNotEmpty) {
              final value = points[0]['value'] as List?;
              if (value != null && value.isNotEmpty) {
                return (value[0]['intVal'] as num?)?.toInt();
              }
            }
          }
        }
      }

      return 0;
    } catch (error) {
      print('Error getting step count: $error');
      return null;
    }
  }

  // Get calories burned for today
  Future<double?> getTodayCalories() async {
    if (_currentUser == null) return null;

    try {
      final authHeaders = await _currentUser!.authHeaders;
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      const String dataTypeName = 'com.google.calories.expended';
      const String url = 'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate';

      final requestBody = {
        'aggregateBy': [
          {
            'dataTypeName': dataTypeName,
          }
        ],
        'bucketByTime': {'durationMillis': 86400000}, // 24 hours
        'startTimeMillis': startOfDay.millisecondsSinceEpoch,
        'endTimeMillis': endOfDay.millisecondsSinceEpoch,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...authHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final buckets = data['bucket'] as List?;
        
        if (buckets != null && buckets.isNotEmpty) {
          final datasets = buckets[0]['dataset'] as List?;
          if (datasets != null && datasets.isNotEmpty) {
            final points = datasets[0]['point'] as List?;
            if (points != null && points.isNotEmpty) {
              final value = points[0]['value'] as List?;
              if (value != null && value.isNotEmpty) {
                return (value[0]['fpVal'] as num?)?.toDouble();
              }
            }
          }
        }
      }

      return 0.0;
    } catch (error) {
      print('Error getting calories: $error');
      return null;
    }
  }

  // Get today's distance traveled (in meters)
  Future<double?> getTodayDistance() async {
    try {
      if (_currentUser == null) {
        print('❌ User not signed in');
        return null;
      }

      print('📏 Getting today\'s distance...');
      
      final auth = await _currentUser!.authentication;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final startTimeNanos = startOfDay.millisecondsSinceEpoch * 1000000;
      final endTimeNanos = now.millisecondsSinceEpoch * 1000000;
      
      // Google Fit distance data source
      final url = 'https://www.googleapis.com/fitness/v1/users/me/dataSources/derived:com.google.distance.delta:com.google.android.gms:merge_distance_delta/dataPointChanges?startTime=${startTimeNanos}ns&endTime=${endTimeNanos}ns';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      print('📏 Distance API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📏 Distance data: $data');
        
        if (data['insertedDataPoint'] != null) {
          double totalDistance = 0.0;
          
          for (var point in data['insertedDataPoint']) {
            if (point['value'] != null && point['value'].isNotEmpty) {
              final distance = point['value'][0]['fpVal'] ?? 0.0;
              totalDistance += distance;
            }
          }
          
          print('📏 Total distance today: ${totalDistance}m');
          return totalDistance > 0 ? totalDistance : null;
        }
      }
      
      print('📏 No distance data found');
      return null;
    } catch (error) {
      print('Error getting distance: $error');
      return null;
    }
  }

  // Get today's move minutes (WHO recommended activity minutes)
  Future<int?> getTodayMoveMinutes() async {
    try {
      if (_currentUser == null) {
        print('❌ User not signed in');
        return null;
      }

      print('⏱️ Getting today\'s move minutes...');
      
      final auth = await _currentUser!.authentication;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final startTimeNanos = startOfDay.millisecondsSinceEpoch * 1000000;
      final endTimeNanos = now.millisecondsSinceEpoch * 1000000;
      
      // Google Fit move minutes data source
      final url = 'https://www.googleapis.com/fitness/v1/users/me/dataSources/derived:com.google.active_minutes:com.google.android.gms:merge_active_minutes/dataPointChanges?startTime=${startTimeNanos}ns&endTime=${endTimeNanos}ns';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      print('⏱️ Move minutes API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('⏱️ Move minutes data: $data');
        
        if (data['insertedDataPoint'] != null) {
          int totalMinutes = 0;
          
          for (var point in data['insertedDataPoint']) {
            if (point['value'] != null && point['value'].isNotEmpty) {
              final minutes = (point['value'][0]['intVal'] ?? 0) as int;
              totalMinutes += minutes;
            }
          }
          
          print('⏱️ Total move minutes today: $totalMinutes min');
          return totalMinutes > 0 ? totalMinutes : null;
        }
      }
      
      print('⏱️ No move minutes data found');
      return null;
    } catch (error) {
      print('Error getting move minutes: $error');
      return null;
    }
  }

  // Get today's average heart rate
  Future<double?> getTodayAverageHeartRate() async {
    try {
      if (_currentUser == null) {
        print('❌ User not signed in');
        return null;
      }

      print('💓 Getting today\'s heart rate...');
      
      final auth = await _currentUser!.authentication;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final startTimeNanos = startOfDay.millisecondsSinceEpoch * 1000000;
      final endTimeNanos = now.millisecondsSinceEpoch * 1000000;
      
      // Google Fit heart rate data source
      final url = 'https://www.googleapis.com/fitness/v1/users/me/dataSources/derived:com.google.heart_rate.bpm:com.google.android.gms:merge_heart_rate_bpm/dataPointChanges?startTime=${startTimeNanos}ns&endTime=${endTimeNanos}ns';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      print('💓 Heart rate API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('💓 Heart rate data: $data');
        
        if (data['insertedDataPoint'] != null) {
          List<double> heartRates = [];
          
          for (var point in data['insertedDataPoint']) {
            if (point['value'] != null && point['value'].isNotEmpty) {
              final heartRate = point['value'][0]['fpVal'] ?? 0.0;
              if (heartRate > 0) {
                heartRates.add(heartRate);
              }
            }
          }
          
          if (heartRates.isNotEmpty) {
            final averageHeartRate = heartRates.reduce((a, b) => a + b) / heartRates.length;
            print('💓 Average heart rate today: ${averageHeartRate.toStringAsFixed(1)} bpm');
            return averageHeartRate;
          }
        }
      }
      
      print('💓 No heart rate data found');
      return null;
    } catch (error) {
      print('Error getting heart rate: $error');
      return null;
    }
  }
}
