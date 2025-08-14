import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_events_service.dart';
import 'models/team.dart';

class CreateTeamEventPage extends StatefulWidget {
  final Team teamData;
  
  const CreateTeamEventPage({super.key, required this.teamData});

  @override
  State<CreateTeamEventPage> createState() => _CreateTeamEventPageState();
}

class _CreateTeamEventPageState extends State<CreateTeamEventPage> {
  final PageController _pageController = PageController();
  final FirebaseEventsService _eventsService = FirebaseEventsService();
  
  int _currentPage = 0;
  
  // Event data
  String _trackingType = ''; // Distance, Time, or Steps
  final List<String> _selectedSports = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _eventName = '';
  String _eventDescription = '';
  
  bool _isCreating = false;

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
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildTrackingTypePage(),
          _buildSportsSelectionPage(),
          _buildDateSelectionPage(),
          _buildEventDetailsPage(),
        ],
      ),
    );
  }

  Widget _buildTrackingTypePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Do you want to track distance, time or steps',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),
          _buildTrackingOption('Distance'),
          const SizedBox(height: 16),
          _buildTrackingOption('Time'),
          const SizedBox(height: 16),
          _buildTrackingOption('Steps'),
          const Spacer(),
          _buildNextButton(
            enabled: _trackingType.isNotEmpty,
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingOption(String type) {
    final isSelected = _trackingType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _trackingType = type;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              type,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.deepPurple : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.deepPurple,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Which sports will count toward your challenge?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),
          _buildSportOption('Walk', Icons.directions_walk),
          const SizedBox(height: 20),
          _buildSportOption('Run', Icons.directions_run),
          const SizedBox(height: 20),
          _buildSportOption('Swim', Icons.pool),
          const SizedBox(height: 20),
          _buildSportOption('Hike', Icons.hiking),
          const SizedBox(height: 20),
          _buildSportOption('Ride', Icons.directions_bike),
          const Spacer(),
          _buildNextButton(
            enabled: _selectedSports.isNotEmpty,
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSportOption(String sport, IconData icon) {
    final isSelected = _selectedSports.contains(sport.toLowerCase());
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSports.remove(sport.toLowerCase());
          } else {
            _selectedSports.add(sport.toLowerCase());
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.black,
            ),
            const SizedBox(width: 20),
            Text(
              sport,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? Colors.deepPurple : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Choose when to kick your challenge off!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            'Start Date',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _selectStartDate(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Text(
                    _startDate != null 
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Choose a Start Date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _startDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'End Date',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _selectEndDate(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Text(
                    _endDate != null 
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Choose an End Date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _endDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildNextButton(
            enabled: _startDate != null && _endDate != null,
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Give your challenge a name.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            'Name',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() {
                _eventName = value;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepPurple),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() {
                _eventDescription = value;
              });
            },
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Optional',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepPurple),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const Spacer(),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildNextButton({required bool enabled, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.grey[600] : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: _eventName.isNotEmpty && !_isCreating ? _createEvent : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _eventName.isNotEmpty && !_isCreating ? Colors.grey[600] : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before the new start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 7)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _createEvent() async {
    if (_eventName.isEmpty || _startDate == null || _endDate == null || _selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create the event data - structured to match Firebase requirements
      final eventData = {
        'name': _eventName,
        'description': _eventDescription.isEmpty ? 'Team challenge for ${widget.teamData.name}' : _eventDescription,
        'businessId': widget.teamData.id, // Use team ID as business ID
        'businessName': widget.teamData.name, // Use team name as business name
        'createdBy': currentUser.uid,
        'sports': _selectedSports,
        'startDate': Timestamp.fromDate(_startDate!), // Use Timestamp for Firebase
        'endDate': Timestamp.fromDate(_endDate!), // Use Timestamp for Firebase
        'participants': [], // Empty participants list - no auto-join
        'maxParticipants': null, // No limit for team events
        'createdAt': Timestamp.fromDate(DateTime.now()), // Use Timestamp for Firebase
        'primaryMetric': _trackingType.toLowerCase(), // Set primary metric at root level
        'primaryMetricDisplayName': _trackingType, // Display name for the metric
        'isLowerBetter': _trackingType.toLowerCase() == 'time', // Time is lower better, others are higher better
        'metrics': {
          'primaryMetric': _trackingType.toLowerCase(),
        },
        'isTeamEvent': true, // Mark as team event
        'teamId': widget.teamData.id, // Link to the specific team
        'teamName': widget.teamData.name, // Store team name for easy reference
      };

      // Create the event
      await _eventsService.createEvent(eventData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team event "$_eventName" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to team details
      Navigator.of(context).pop(true); // Return true to indicate success

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
