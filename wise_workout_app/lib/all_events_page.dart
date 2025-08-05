import 'package:flutter/material.dart';
import 'services/firebase_events_service.dart';
import 'models/event.dart';
import 'joined_events_state.dart';
import 'event_page.dart';
import 'event_details_page.dart';

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({super.key});

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage> {
  final FirebaseEventsService _eventsService = FirebaseEventsService();
  final JoinedEventsState _joinedEventsState = JoinedEventsState();
  bool _isLoading = true;
  List<Event> _joinedEvents = [];

  @override
  void initState() {
    super.initState();
    _joinedEventsState.addListener(_onJoinedEventsChanged);
    _loadJoinedEvents();
  }

  @override
  void dispose() {
    _joinedEventsState.removeListener(_onJoinedEventsChanged);
    super.dispose();
  }

  void _onJoinedEventsChanged() {
    // Reload events when joined events state changes
    if (mounted) {
      _loadJoinedEvents();
    }
  }

  Future<void> _loadJoinedEvents() async {
    try {
      setState(() => _isLoading = true);
      
      await _eventsService.loadEvents();
      
      // Filter events using both Firebase data and global state
      String? currentUserId = _eventsService.currentUserId;
      if (currentUserId != null) {
        _joinedEvents = _eventsService.allEvents.where((event) {
          // Check both Firebase participants and global state
          bool isInFirebase = event.participants.contains(currentUserId);
          bool isInGlobalState = _joinedEventsState.isEventJoined(event.id);
          
          // Event is considered joined if it's in either source
          // This handles cases where local state is ahead of Firebase sync
          return isInFirebase || isInGlobalState;
        }).toList();
      }
      
      print('📅 Found ${_joinedEvents.length} joined events for user');
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading joined events: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _getEventIcon(String sportType) {
    IconData iconData;
    switch (sportType) {
      case 'Run':
        iconData = Icons.directions_run;
        break;
      case 'Ride':
        iconData = Icons.directions_bike;
        break;
      case 'Swim':
        iconData = Icons.pool;
        break;
      case 'Walk':
        iconData = Icons.directions_walk;
        break;
      case 'Hike':
        iconData = Icons.hiking;
        break;
      default:
        iconData = Icons.event;
    }
    return Icon(iconData, size: 24, color: Colors.orange);
  }

  Future<void> _leaveEvent(Event event) async {
    try {
      bool success = await _eventsService.leaveEvent(event.id);
      
      if (success) {
        // Update the global joined events state
        _joinedEventsState.leaveEvent(event.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left ${event.name} successfully!')),
        );
        // Reload the joined events list
        _loadJoinedEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to leave event. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error leaving event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLeaveEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Event'),
          content: Text('Are you sure you want to leave "${event.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _leaveEvent(event);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Events',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventPage()),
              );
            },
            tooltip: 'Browse Events',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadJoinedEvents,
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _joinedEvents.isEmpty
              ? _buildEmptyState()
              : _buildEventsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Joined Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t joined any events yet.\nExplore events and join some!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to the event page to browse events
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const EventPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Browse Events'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return RefreshIndicator(
      onRefresh: _loadJoinedEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _joinedEvents.length,
        itemBuilder: (context, index) {
          final event = _joinedEvents[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(event: event),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event header with icon and name
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _getEventIcon(event.sportType),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${event.businessName}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sport type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.sportType,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Event description
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Event details
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.dateRange,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participants.length}/${event.maxParticipants}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Joined indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Joined',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      
                      // Leave event button
                      TextButton(
                        onPressed: () => _showLeaveEventDialog(event),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.red.withOpacity(0.3)),
                          ),
                        ),
                        child: const Text(
                          'Leave Event',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ));
        },
      ),
    );
  }
}
