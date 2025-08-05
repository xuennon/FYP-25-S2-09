import 'package:flutter/material.dart';
import 'models/event.dart';
import 'joined_events_state.dart';
import 'services/firebase_events_service.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool isJoined = false;
  final JoinedEventsState _joinedEventsState = JoinedEventsState();
  final FirebaseEventsService _eventsService = FirebaseEventsService();

  @override
  void initState() {
    super.initState();
    // Check if this event is already joined
    isJoined = _joinedEventsState.isEventJoined(widget.event.id);
    
    // Listen to joined events state changes
    _joinedEventsState.addListener(_onJoinedEventsChanged);
  }

  @override
  void dispose() {
    _joinedEventsState.removeListener(_onJoinedEventsChanged);
    super.dispose();
  }

  void _onJoinedEventsChanged() {
    if (mounted) {
      setState(() {
        isJoined = _joinedEventsState.isEventJoined(widget.event.id);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Event',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Event Icon (smaller size)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getEventIcon(widget.event.sportType),
                size: 40,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 30),
            // Event Name
            Text(
              widget.event.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Event Description
            Text(
              widget.event.description.isNotEmpty ? widget.event.description : 'walk dont run',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Join Challenge Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (isJoined) {
                    _leaveEvent();
                  } else {
                    _joinEvent();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined ? Colors.grey : Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isJoined ? 'Leave Event' : 'Join Event',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Event Date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.event.dateRange,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'run':
        return Icons.directions_run;
      case 'ride':
        return Icons.directions_bike;
      case 'swim':
        return Icons.pool;
      case 'walk':
        return Icons.directions_walk;
      case 'hike':
        return Icons.hiking;
      default:
        return Icons.directions_walk; // Default to walk icon
    }
  }

  Future<void> _joinEvent() async {
    try {
      // Update local state immediately for instant UI feedback
      setState(() {
        isJoined = true;
      });
      
      // Update global state
      _joinedEventsState.joinEvent(widget.event.id);
      
      // Update the event object's isActive property
      widget.event.isActive = true;
      
      // Sync with Firebase
      bool success = await _eventsService.joinEvent(widget.event.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined ${widget.event.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Revert changes if Firebase update failed
        setState(() {
          isJoined = false;
        });
        _joinedEventsState.leaveEvent(widget.event.id);
        widget.event.isActive = false;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to join event. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert changes if there was an error
      setState(() {
        isJoined = false;
      });
      _joinedEventsState.leaveEvent(widget.event.id);
      widget.event.isActive = false;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveEvent() async {
    try {
      // Update local state immediately for instant UI feedback
      setState(() {
        isJoined = false;
      });
      
      // Update global state
      _joinedEventsState.leaveEvent(widget.event.id);
      
      // Update the event object's isActive property
      widget.event.isActive = false;
      
      // Sync with Firebase
      bool success = await _eventsService.leaveEvent(widget.event.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully left ${widget.event.name}!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Revert changes if Firebase update failed
        setState(() {
          isJoined = true;
        });
        _joinedEventsState.joinEvent(widget.event.id);
        widget.event.isActive = true;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to leave event. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert changes if there was an error
      setState(() {
        isJoined = true;
      });
      _joinedEventsState.joinEvent(widget.event.id);
      widget.event.isActive = true;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
