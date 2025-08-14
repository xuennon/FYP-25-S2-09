import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/firebase_subscription_service.dart';
import 'subscription_page.dart';

class ActivityDetailsPage extends StatefulWidget {
  final ActivityDetail activity;

  const ActivityDetailsPage({super.key, required this.activity});

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  final FirebaseSubscriptionService _subscriptionService = FirebaseSubscriptionService();
  bool _isPremiumUser = false;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      String userType = await _subscriptionService.getUserSubscriptionType();
      setState(() {
        _isPremiumUser = userType == 'premium';
        _isLoadingSubscription = false;
      });
    } catch (e) {
      setState(() {
        _isPremiumUser = false;
        _isLoadingSubscription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and timestamp
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activity.userColor,
                  ),
                  child: Center(
                    child: Text(
                      activity.userInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.date,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Activity title
            Text(
              activity.activityType,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Activity metrics in 2x3 grid
            Column(
              children: [
                // First row: Distance and Pace
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailedMetric(
                        'Distance',
                        activity.distance,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildDetailedMetric(
                        'Average Pace',
                        _formatPaceValue(),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Second row: Moving Time and Steps
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailedMetric(
                        'Moving Time',
                        activity.movingTime,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildDetailedMetric(
                        'Steps',
                        activity.steps,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Third row: Calories and Avg Heart Rate
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailedMetric(
                        'Calories',
                        activity.calories,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildDetailedMetric(
                        'Avg Heart Rate',
                        activity.avgHeartRate,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),
                
                // Pace Chart Section - Premium Feature
                if (_isLoadingSubscription)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  )
                else if (_isPremiumUser)
                  _buildChartSection(
                    'Pace Analysis',
                    _buildPaceChart(),
                    _buildPaceAnalysis(),
                  )
                else
                  _buildPremiumGate('Pace Analysis'),
                
                const SizedBox(height: 40),
                
                // Cadence Chart Section - Premium Feature
                if (_isLoadingSubscription)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  )
                else if (_isPremiumUser)
                  _buildChartSection(
                    'Cadence Analysis',
                    _buildCadenceChart(),
                    _buildCadenceAnalysis(),
                  )
                else
                  _buildPremiumGate('Cadence Analysis'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(String title, Widget chart, Widget analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: chart,
        ),
        const SizedBox(height: 16),
        analysis,
      ],
    );
  }

  Widget _buildPaceChart() {
    // Generate realistic pace data based on actual activity metrics
    List<FlSpot> paceData = _generatePaceData();

    double minPace = paceData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double maxPace = paceData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    
    // Add some padding to the min/max values
    double padding = (maxPace - minPace) * 0.1;
    minPace = (minPace - padding).clamp(0.0, double.infinity);
    maxPace = maxPace + padding;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: paceData,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
        minY: minPace,
        maxY: maxPace,
      ),
    );
  }

  List<FlSpot> _generatePaceData() {
    final activity = widget.activity;
    // Use Firebase pace data points if available
    if (activity.firebasePaceDataPoints != null && activity.firebasePaceDataPoints!.isNotEmpty) {
      List<FlSpot> spots = [];
      for (int i = 0; i < activity.firebasePaceDataPoints!.length; i++) {
        spots.add(FlSpot(i.toDouble(), activity.firebasePaceDataPoints![i]));
      }
      return spots;
    }
    
    // Fallback to calculated data
    double basePace = activity.avgPace > 0 ? activity.avgPace : 6.0;
    
    // Generate 10-15 data points with realistic variations
    List<FlSpot> spots = [];
    int dataPoints = 10;
    
    for (int i = 0; i < dataPoints; i++) {
      // Create realistic pace variations
      double variation = (i / dataPoints) * 0.5 - 0.25; // ±0.25 min/km variation
      double paceVariation = 0.1 * (0.5 - (i % 3) / 6.0); // Small random-like variation
      double pace = basePace + variation + paceVariation;
      
      spots.add(FlSpot(i.toDouble(), pace));
    }
    
    return spots;
  }

  Widget _buildPaceAnalysis() {
    final activity = widget.activity;
    // Use Firebase data if available, otherwise calculate
    double avgPace = activity.avgPace > 0 ? activity.avgPace : 0.0;
    String avgPaceStr = avgPace > 0 ? '${avgPace.toStringAsFixed(1)} min/km' : 'N/A';
    
    // Use Firebase best pace if available
    double bestPace = activity.firebaseBestPace ?? (avgPace > 0 ? avgPace * 0.85 : 0.0);
    String bestPaceStr = bestPace > 0 ? '${bestPace.toStringAsFixed(1)} min/km' : 'N/A';
    
    // Use Firebase pace zone if available
    String paceZone = activity.firebasePaceZone ?? _getPaceZone(avgPace);
    String analysis = _getPaceAnalysis(avgPace, activity.activityType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Pace Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (activity.firebasePaceZone != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalyticItem('Average Pace', avgPaceStr, Colors.blue),
              _buildAnalyticItem('Best Pace', bestPaceStr, Colors.green),
              _buildAnalyticItem('Pace Zone', paceZone, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaceZone(double avgPace) {
    if (avgPace <= 0) return 'Unknown';
    if (avgPace < 4.0) return 'Elite';
    if (avgPace < 5.0) return 'Fast';
    if (avgPace < 6.0) return 'Good';
    if (avgPace < 7.0) return 'Moderate';
    if (avgPace < 8.0) return 'Easy';
    return 'Relaxed';
  }

  String _getPaceAnalysis(double avgPace, String activityType) {
    if (avgPace <= 0) {
      return 'Pace data not available for this ${activityType.toLowerCase()} activity.';
    }
    
    String zone = _getPaceZone(avgPace);
    String activityName = activityType.toLowerCase();
    
    switch (zone) {
      case 'Elite':
        return 'Outstanding $activityName pace! You\'re performing at an elite level with exceptional speed and endurance.';
      case 'Fast':
        return 'Excellent $activityName pace! You maintained a fast, competitive speed throughout your workout.';
      case 'Good':
        return 'Great $activityName pace! You showed good speed control and maintained a solid rhythm.';
      case 'Moderate':
        return 'Good $activityName pace for endurance building. This moderate intensity is excellent for aerobic fitness.';
      case 'Easy':
        return 'Comfortable $activityName pace, perfect for recovery sessions and building aerobic base fitness.';
      case 'Relaxed':
        return 'Relaxed $activityName pace, ideal for active recovery and enjoying the movement.';
      default:
        return 'Your pace shows consistent effort throughout the $activityName session.';
    }
  }

  Widget _buildCadenceChart() {
    // Generate realistic cadence data based on actual activity metrics
    List<FlSpot> cadenceData = _generateCadenceData();

    double minCadence = cadenceData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double maxCadence = cadenceData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    
    // Add some padding to the min/max values
    double padding = (maxCadence - minCadence) * 0.1;
    minCadence = (minCadence - padding).clamp(0.0, double.infinity);
    maxCadence = maxCadence + padding;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: cadenceData,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        ],
        minY: minCadence,
        maxY: maxCadence,
      ),
    );
  }

  List<FlSpot> _generateCadenceData() {
    final activity = widget.activity;
    // Use Firebase cadence data points if available
    if (activity.firebaseCadenceDataPoints != null && activity.firebaseCadenceDataPoints!.isNotEmpty) {
      List<FlSpot> spots = [];
      for (int i = 0; i < activity.firebaseCadenceDataPoints!.length; i++) {
        spots.add(FlSpot(i.toDouble(), activity.firebaseCadenceDataPoints![i]));
      }
      return spots;
    }
    
    // Fallback to calculated data
    double baseCadence = _calculateEstimatedCadence();
    
    // Generate 10-15 data points with realistic variations
    List<FlSpot> spots = [];
    int dataPoints = 10;
    
    for (int i = 0; i < dataPoints; i++) {
      // Create realistic cadence variations (±5-10 spm)
      double variation = (i / dataPoints) * 10 - 5; // ±5 spm variation over time
      double randomVariation = 3 * (0.5 - (i % 4) / 8.0); // Small random-like variation
      double cadence = baseCadence + variation + randomVariation;
      
      // Ensure cadence stays within reasonable bounds
      cadence = cadence.clamp(140.0, 200.0);
      
      spots.add(FlSpot(i.toDouble(), cadence));
    }
    
    return spots;
  }

  double _calculateEstimatedCadence() {
    final activity = widget.activity;
    // Estimate cadence from total steps and duration
    if (activity.totalSteps > 0 && activity.durationSeconds > 0) {
      // Steps per minute = (total steps / duration in minutes)
      double stepsPerMinute = activity.totalSteps / (activity.durationSeconds / 60.0);
      return stepsPerMinute;
    }
    
    // Default cadence based on activity type if no step data
    switch (activity.activityType.toLowerCase()) {
      case 'run':
      case 'running':
        return 170.0; // Typical running cadence
      case 'walk':
      case 'walking':
        return 120.0; // Typical walking cadence
      case 'hiking':
        return 110.0; // Typical hiking cadence
      default:
        return 160.0; // General default
    }
  }

  Widget _buildCadenceAnalysis() {
    final activity = widget.activity;
    // Use Firebase cadence data if available, otherwise calculate
    final avgCadence = activity.firebaseAvgCadence ?? _calculateEstimatedCadence();
    final peakCadence = activity.firebasePeakCadence ?? (avgCadence * 1.08);
    final consistencyRating = activity.firebaseCadenceConsistency ?? _getCadenceConsistency(avgCadence, activity.activityType);
    final isUsingFirebaseData = activity.firebaseAvgCadence != null;
    
    String avgCadenceStr = '${avgCadence.toInt()} spm';
    String peakCadenceStr = '${peakCadence.toInt()} spm';
    String analysis = isUsingFirebaseData 
        ? 'Analysis based on stored workout data from your activity session.'
        : _getCadenceAnalysis(avgCadence, activity.activityType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Cadence Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              // Sync indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUsingFirebaseData ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUsingFirebaseData ? Icons.cloud_done : Icons.cloud_off,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUsingFirebaseData ? 'Synced' : 'Local',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalyticItem('Avg Cadence', avgCadenceStr, Colors.green),
              _buildAnalyticItem('Peak Cadence', peakCadenceStr, Colors.blue),
              _buildAnalyticItem('Consistency', consistencyRating, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (isUsingFirebaseData) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data synchronized from Firebase storage',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Using estimated data - sync to Firebase for precise analytics',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCadenceConsistency(double avgCadence, String activityType) {
    // Base consistency rating on cadence range for activity type
    double optimalCadence = _getOptimalCadence(activityType);
    double deviation = (avgCadence - optimalCadence).abs();
    
    if (deviation < 5) return 'Excellent';
    if (deviation < 10) return 'Good';
    if (deviation < 15) return 'Fair';
    return 'Needs Work';
  }

  double _getOptimalCadence(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'run':
      case 'running':
        return 170.0; // Optimal running cadence
      case 'walk':
      case 'walking':
        return 120.0; // Optimal walking cadence
      case 'hiking':
        return 110.0; // Optimal hiking cadence
      default:
        return 160.0;
    }
  }

  String _getCadenceAnalysis(double avgCadence, String activityType) {
    String activityName = activityType.toLowerCase();
    double optimalCadence = _getOptimalCadence(activityType);
    String consistency = _getCadenceConsistency(avgCadence, activityType);
    
    if (avgCadence >= optimalCadence - 5 && avgCadence <= optimalCadence + 5) {
      return 'Excellent $activityName cadence! You maintained an optimal step frequency that promotes efficiency and reduces injury risk.';
    } else if (avgCadence > optimalCadence + 5) {
      return 'High $activityName cadence detected. While energetic, consider slightly reducing step frequency for better efficiency and endurance.';
    } else if (avgCadence < optimalCadence - 10) {
      return 'Lower $activityName cadence observed. Try increasing your step frequency slightly to improve efficiency and reduce ground contact time.';
    } else {
      return 'Good $activityName rhythm with $consistency consistency. Your cadence shows steady movement patterns throughout the session.';
    }
  }

  Widget _buildAnalyticItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatPaceValue() {
    final activity = widget.activity;
    // Use Firebase best pace if available, otherwise use average pace
    double displayPace = activity.firebaseBestPace ?? activity.avgPace;
    
    if (displayPace <= 0) {
      return 'N/A';
    }
    
    return '${displayPace.toStringAsFixed(1)} min/km';
  }

  Widget _buildPremiumGate(String featureName) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            featureName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock advanced fitness metrics analysis',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
              ).then((_) {
                // Refresh subscription status when returning from subscription page
                _checkSubscriptionStatus();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Upgrade to Premium',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Premium features include detailed pace and cadence analysis',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityDetail {
  final String id;
  final String userName;
  final String userInitial;
  final String activityType;
  final String date;
  final String distance;
  final String elevationGain;
  final String movingTime;
  final String steps;
  final String calories;
  final String avgHeartRate;
  final Color userColor;
  
  // Additional numerical data for analysis
  final double distanceKm;
  final int durationSeconds;
  final double avgPace;
  final int totalSteps;
  final int totalCalories;
  final int avgHeartRateValue;
  
  // Firebase-linked analytics data
  final double? firebaseAvgCadence;
  final double? firebasePeakCadence;
  final double? firebaseBestPace;
  final String? firebasePaceZone;
  final String? firebaseCadenceConsistency;
  final List<double>? firebasePaceDataPoints;
  final List<double>? firebaseCadenceDataPoints;

  ActivityDetail({
    required this.id,
    required this.userName,
    required this.userInitial,
    required this.activityType,
    required this.date,
    required this.distance,
    required this.elevationGain,
    required this.movingTime,
    required this.steps,
    required this.calories,
    required this.avgHeartRate,
    required this.userColor,
    this.distanceKm = 0.0,
    this.durationSeconds = 0,
    this.avgPace = 0.0,
    this.totalSteps = 0,
    this.totalCalories = 0,
    this.avgHeartRateValue = 0,
    this.firebaseAvgCadence,
    this.firebasePeakCadence,
    this.firebaseBestPace,
    this.firebasePaceZone,
    this.firebaseCadenceConsistency,
    this.firebasePaceDataPoints,
    this.firebaseCadenceDataPoints,
  });
}
