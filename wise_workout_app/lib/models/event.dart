import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final String businessId; // ID of the business that created this event (same as createdBy)
  final String businessName; // Name of the business
  final String createdBy; // User ID who created this event
  final List<String> sports; // List of sports: ['run', 'ride', 'swim', 'walk', 'hike']
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants; // List of user IDs who joined
  final int? maxParticipants; // Optional limit on participants
  bool isActive; // Whether current user has joined this event
  final DateTime createdAt;
  final Map<String, dynamic>? metrics; // Metrics data (e.g., elevation)

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.businessId,
    required this.businessName,
    required this.createdBy,
    required this.sports,
    required this.startDate,
    required this.endDate,
    required this.participants,
    this.maxParticipants,
    this.isActive = false,
    required this.createdAt,
    this.metrics,
  });

  // Get formatted date range
  String get dateRange {
    final startFormatted = '${_getMonthAbbr(startDate.month)} ${startDate.day}';
    final endFormatted = '${_getMonthAbbr(endDate.month)} ${endDate.day}, ${endDate.year}';
    return '$startFormatted to $endFormatted';
  }

  // Alternative method name for compatibility
  String formatDateRange() {
    return dateRange;
  }

  // Get participant count
  int get participantCount => participants.length;

  // Check if event is full
  bool get isFull => maxParticipants != null && participantCount >= maxParticipants!;
  
  // Alternative method name for compatibility
  bool get isEventFull => isFull;

  // Check if event is ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Check if event has ended
  bool get hasEnded => DateTime.now().isAfter(endDate);

  // Check if event is upcoming
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  // Compatibility getter for sportType (returns first sport or 'All' if multiple)
  String get sportType {
    if (sports.isEmpty) return 'All';
    if (sports.length == 1) return _capitalizeSport(sports.first);
    return 'All'; // Multiple sports
  }

  // Get primary sport (first sport in the list)
  String get primarySport {
    if (sports.isEmpty) return 'All';
    return _capitalizeSport(sports.first);
  }

  // Get all sports as formatted string
  String get sportsDisplay {
    if (sports.isEmpty) return 'All';
    return sports.map((sport) => _capitalizeSport(sport)).join(', ');
  }

  // Check if event contains a specific sport
  bool containsSport(String sport) {
    return sports.contains(sport.toLowerCase());
  }

  // Get elevation from metrics (if available)
  double? get elevation {
    if (metrics == null) return null;
    return metrics!['elevation']?.toDouble();
  }

  String _capitalizeSport(String sport) {
    if (sport.isEmpty) return sport;
    return sport[0].toUpperCase() + sport.substring(1).toLowerCase();
  }

  String _getMonthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  // Convert Event to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'businessId': businessId,
      'businessName': businessName,
      'sports': sports,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'participants': participants,
      'maxParticipants': maxParticipants,
      'createdAt': createdAt.toIso8601String(),
      if (metrics != null) 'metrics': metrics,
    };
  }

  // Create Event from Map (alternative constructor)
  factory Event.fromMap(String id, Map<String, dynamic> map) {
    try {
      // Safely parse sports field - handle different formats
      List<String> sportsList = [];
      if (map['sports'] != null) {
        if (map['sports'] is List) {
          sportsList = List<String>.from(map['sports']);
        } else if (map['sports'] is String) {
          sportsList = [map['sports']];
        }
      } else if (map['sportType'] != null) {
        // Fallback to old format
        sportsList = [map['sportType'].toString()];
      }
      
      // Safely parse dates - handle both String and Timestamp
      DateTime parseDate(dynamic dateValue, DateTime fallback) {
        if (dateValue == null) return fallback;
        
        try {
          if (dateValue is Timestamp) {
            return dateValue.toDate();
          } else if (dateValue is String) {
            return DateTime.parse(dateValue);
          }
        } catch (e) {
          print('⚠️ Date parsing error for $dateValue: $e');
        }
        return fallback;
      }
      
      // Handle date parsing for both old and new formats
      DateTime startDate = parseDate(
        map['startDate'] ?? map['start'], 
        DateTime.now()
      );
      
      DateTime endDate = parseDate(
        map['endDate'] ?? map['end'], 
        startDate.add(const Duration(hours: 2))
      );
      
      DateTime createdAt = parseDate(
        map['createdAt'], 
        DateTime.now()
      );
      
      // Safely parse participants
      List<String> participants = [];
      if (map['participants'] != null && map['participants'] is List) {
        participants = List<String>.from(map['participants']);
      }
      
      // Safely parse metrics
      Map<String, dynamic>? metrics;
      if (map['metrics'] != null && map['metrics'] is Map) {
        metrics = Map<String, dynamic>.from(map['metrics']);
      }

      return Event(
        id: id,
        name: map['name']?.toString() ?? 'Unnamed Event',
        description: map['description']?.toString() ?? '',
        createdBy: map['createdBy']?.toString() ?? map['businessId']?.toString() ?? '',
        businessId: map['businessId']?.toString() ?? map['createdBy']?.toString() ?? '',
        businessName: map['businessName']?.toString() ?? 'Unknown Business',
        sports: sportsList,
        startDate: startDate,
        endDate: endDate,
        participants: participants,
        maxParticipants: map['maxParticipants'] is int ? map['maxParticipants'] : null,
        createdAt: createdAt,
        metrics: metrics,
      );
    } catch (e, stackTrace) {
      print('❌ Error creating Event from map: $e');
      print('📄 Raw data: $map');
      print('📍 Stack trace: $stackTrace');
      
      // Return a safe fallback event
      return Event(
        id: id,
        name: 'Error Loading Event',
        description: 'Failed to load event data',
        createdBy: '',
        businessId: '',
        businessName: 'Unknown',
        sports: ['All'],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(hours: 2)),
        participants: [],
        maxParticipants: null,
        createdAt: DateTime.now(),
        metrics: null,
      );
    }
  }
}
