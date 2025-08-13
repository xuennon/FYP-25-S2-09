import 'package:flutter/material.dart';
import 'models/event.dart';
import 'models/leaderboard.dart';
import 'joined_events_state.dart';
import 'shortlist_events_state.dart';
import 'services/firebase_events_service.dart';
import 'services/leaderboard_service.dart';
import 'widgets/leaderboard_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool isJoined = false;
  bool isShortlisted = false;
  final JoinedEventsState _joinedEventsState = JoinedEventsState();
  final ShortlistEventsState _shortlistEventsState = ShortlistEventsState();
  final FirebaseEventsService _eventsService = FirebaseEventsService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  late Stream<EventLeaderboard?> _leaderboardStream;

  @override
  void initState() {
    super.initState();
    // Check if this event is already joined
    isJoined = _joinedEventsState.isEventJoined(widget.event.id);
    
    // Initialize shortlist state from shared state manager
    isShortlisted = _shortlistEventsState.isEventShortlisted(widget.event.id);
    
    // Listen to joined events state changes
    _joinedEventsState.addListener(_onJoinedEventsChanged);
    
    // Listen to shortlist state changes
    _shortlistEventsState.addListener(_onShortlistChanged);
    
    // Initialize leaderboard stream
    _leaderboardStream = _leaderboardService.streamEventLeaderboard(widget.event.id);
    
    // Load initial leaderboard
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _joinedEventsState.removeListener(_onJoinedEventsChanged);
    _shortlistEventsState.removeListener(_onShortlistChanged);
    super.dispose();
  }

  void _onJoinedEventsChanged() {
    if (mounted) {
      setState(() {
        isJoined = _joinedEventsState.isEventJoined(widget.event.id);
      });
    }
  }

  void _onShortlistChanged() {
    if (mounted) {
      setState(() {
        isShortlisted = _shortlistEventsState.isEventShortlisted(widget.event.id);
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      // Initial load is now handled by StreamBuilder
      // This method can be used for manual refresh if needed
      print('🔄 Leaderboard stream initialized for event ${widget.event.id}');
      print('🎯 Event details: ${widget.event.name} | Sport: ${widget.event.sportType}');
    } catch (e) {
      print('❌ Error initializing leaderboard: $e');
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
            icon: Icon(
              isShortlisted ? Icons.star : Icons.star_border,
              color: isShortlisted ? Colors.orange : Colors.black,
            ),
            onPressed: () async {
              // Use the shared shortlist state manager with Firebase sync
              await _shortlistEventsState.toggleShortlist(widget.event.id);
              
              // Update local state for immediate UI feedback
              setState(() {
                isShortlisted = _shortlistEventsState.isEventShortlisted(widget.event.id);
              });
              
              // Debug logging
              print('⭐ Shortlist toggled for event: ${widget.event.id}');
              print('⭐ Current shortlist state: $isShortlisted');
              print('⭐ All shortlisted IDs: ${_shortlistEventsState.shortlistedEventIds}');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isShortlisted 
                        ? 'Added ${widget.event.name} to shortlist'
                        : 'Removed ${widget.event.name} from shortlist'
                  ),
                  backgroundColor: isShortlisted ? Colors.green : Colors.orange,
                ),
              );
            },
            tooltip: isShortlisted ? 'Remove from shortlist' : 'Add to shortlist',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
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
              const SizedBox(height: 40),
              // Leaderboard Section
              StreamBuilder<EventLeaderboard?>(
                stream: _leaderboardStream,
                builder: (context, snapshot) {
                  print('📡 StreamBuilder state: ${snapshot.connectionState}');
                  print('📊 Has data: ${snapshot.hasData}');
                  print('❌ Has error: ${snapshot.hasError}');
                  if (snapshot.hasError) {
                    print('🚨 Error details: ${snapshot.error}');
                  }
                  
                  // Debug current user and event info
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  print('👤 Current user ID: $currentUserId');
                  print('🎯 Event ID: ${widget.event.id}');
                  print('🏃 Event participants: ${widget.event.participants}');
                  print('👥 User is in participants: ${widget.event.participants.contains(currentUserId)}');
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error loading leaderboard: ${snapshot.error}',
                        style: TextStyle(color: Colors.red[600]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  
                  EventLeaderboard? leaderboard = snapshot.data;
                  
                  // Debug leaderboard entries
                  if (leaderboard != null) {
                    print('📊 Leaderboard entries count: ${leaderboard.entries.length}');
                    for (int i = 0; i < leaderboard.entries.length; i++) {
                      final entry = leaderboard.entries[i];
                      print('  Entry $i: ${entry.username} (${entry.userId}) - in participants: ${widget.event.participants.contains(entry.userId)}');
                    }
                  }
                  
                  // Always show leaderboard layout, even if empty
                  if (leaderboard != null && leaderboard.entries.isNotEmpty) {
                    // Show leaderboard with actual data
                    return LeaderboardWidget(
                      leaderboard: leaderboard,
                      currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    );
                  } else {
                    // Show empty leaderboard layout
                    EventLeaderboard emptyLeaderboard = EventLeaderboard(
                      eventId: widget.event.id,
                      entries: [], // Empty list
                      lastUpdated: DateTime.now(),
                    );
                    
                    return LeaderboardWidget(
                      leaderboard: emptyLeaderboard,
                      currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
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
      
      // Remove current user from participants locally for immediate UI update
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        widget.event.participants.remove(currentUserId);
        print('👤 Removed user $currentUserId from local participants list');
        print('👥 Updated participants: ${widget.event.participants}');
      }
      
      // Sync with Firebase
      bool success = await _eventsService.leaveEvent(widget.event.id);
      
      if (success) {
        // Force refresh the leaderboard stream to update immediately
        setState(() {
          _leaderboardStream = _leaderboardService.streamEventLeaderboard(widget.event.id);
        });
        
        print('✅ Successfully left event, leaderboard stream refreshed');
        
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
        if (currentUserId != null) {
          widget.event.participants.add(currentUserId);
        }
        
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
