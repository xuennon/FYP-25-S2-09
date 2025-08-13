import 'dart:async';
import 'package:flutter/material.dart';
import 'services/workout_service.dart';

class WorkoutRecordPage extends StatefulWidget {
  const WorkoutRecordPage({Key? key}) : super(key: key);

  @override
  State<WorkoutRecordPage> createState() => _WorkoutRecordPageState();
}

class _WorkoutRecordPageState extends State<WorkoutRecordPage> {
  // Timer related variables
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  // Workout data
  double _distance = 0.0; // in km
  double _pace = 0.0; // in min/km
  int _steps = 0;
  int _calories = 0;

  // Selected sport
  String _selectedSport = 'Walk';
  IconData _selectedSportIcon = Icons.directions_walk;

  // Available sports
  final Map<String, IconData> _sports = {
    'Walk': Icons.directions_walk,
    'Run': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'Hiking': Icons.terrain,
    'Swimming': Icons.pool,
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPauseTimer() {
    if (_isRunning) {
      // Pause the timer
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        _isPaused = true;
      });
    } else {
      // Start the timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
          _updateWorkoutData();
        });
      });
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });
    }
  }

  void _resumeTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _updateWorkoutData();
      });
    });
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
  }

  Future<void> _finishWorkout() async {
    _timer?.cancel();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Saving workout...'),
            ],
          ),
        );
      },
    );
    
    // Create workout activity and save it
    final workoutActivity = WorkoutActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sportType: _selectedSport,
      date: DateTime.now(),
      durationSeconds: _seconds,
      distanceKm: _distance,
      steps: _steps,
      calories: _calories,
      avgPace: _pace,
    );
    
    // Save to workout service and sync to leaderboards
    await WorkoutService().addActivity(workoutActivity);
    
    // Close loading dialog
    Navigator.pop(context);
    
    // Show workout summary
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Workout Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activity: $_selectedSport'),
              Text('Duration: ${_formatTime(_seconds)}'),
              Text('Distance: ${_distance.toStringAsFixed(2)} km'),
              Text('Steps: $_steps'),
              Text('Calories: $_calories kcal'),
              const SizedBox(height: 10),
              const Text(
                '✅ Saved to Firebase and synced to leaderboards!',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous page
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _updateWorkoutData() {
    // Simulate real-time data updates
    // In a real app, you would get this data from sensors/GPS
    if (_isRunning) {
      // Simulate distance increase (varies by sport)
      double speedMultiplier = _getSpeedMultiplier();
      _distance += (speedMultiplier / 3600); // Convert to km per second
      
      // Calculate pace (min/km)
      if (_distance > 0) {
        double timeInMinutes = _seconds / 60.0;
        _pace = timeInMinutes / _distance;
      }
      
      // Simulate steps (only for walking/running)
      if (_selectedSport == 'Walk' || _selectedSport == 'Run') {
        _steps += _selectedSport == 'Walk' ? 1 : 2; // Run has more steps per second
      }
      
      // Calculate calories (rough estimation)
      _calories = (_seconds * _getCalorieRate()).round();
    }
  }

  double _getSpeedMultiplier() {
    switch (_selectedSport) {
      case 'Walk':
        return 5.0; // 5 km/h
      case 'Run':
        return 10.0; // 10 km/h
      case 'Cycling':
        return 20.0; // 20 km/h
      case 'Hiking':
        return 3.0; // 3 km/h
      case 'Swimming':
        return 2.0; // 2 km/h equivalent
      default:
        return 5.0;
    }
  }

  double _getCalorieRate() {
    switch (_selectedSport) {
      case 'Walk':
        return 0.08; // calories per second
      case 'Run':
        return 0.15;
      case 'Cycling':
        return 0.12;
      case 'Hiking':
        return 0.10;
      case 'Swimming':
        return 0.18;
      default:
        return 0.08;
    }
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showSportSelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose a Sport',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ..._sports.entries.map((entry) {
                bool isSelected = entry.key == _selectedSport;
                return ListTile(
                  leading: Icon(
                    entry.value,
                    color: isSelected ? Colors.orange : Colors.grey[600],
                  ),
                  title: Text(
                    entry.key,
                    style: TextStyle(
                      color: isSelected ? Colors.orange : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.orange)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSport = entry.key;
                      _selectedSportIcon = entry.value;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _formatTime(_seconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Metrics display
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      value: _distance.toStringAsFixed(2),
                      label: 'Distance (km)',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildMetricCard(
                      value: _pace.toStringAsFixed(2),
                      label: 'Pace (min/km)',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      value: _steps.toString(),
                      label: 'Steps',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildMetricCard(
                      value: _calories.toString(),
                      label: 'Calories (kcal)',
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Control buttons - different layouts based on state
              if (!_isRunning && !_isPaused) ...[
                // Initial state: Sport selection + Start + Reset
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Sport selection button
                    GestureDetector(
                      onTap: _showSportSelectionDialog,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedSportIcon,
                              size: 30,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedSport,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Start button
                    GestureDetector(
                      onTap: _startPauseTimer,
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    // Invisible spacer to maintain original positioning
                    const SizedBox(
                      width: 70,
                      height: 70,
                    ),
                  ],
                ),
              ] else if (_isRunning) ...[
                // Running state: Only Pause button (full width)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: _startPauseTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pause, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Pause',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_isPaused) ...[
                // Paused state: Resume + Finish buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: ElevatedButton(
                          onPressed: _resumeTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Resume',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                          onPressed: _finishWorkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Finish',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
