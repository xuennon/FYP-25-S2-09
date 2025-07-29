class Event {
  final String id;
  final String name;
  final String description;
  final String businessId; // ID of the business that created this event
  final String businessName; // Name of the business
  final String sportType; // Run, Ride, Swim, Walk, Hike, All
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants; // List of user IDs who joined
  final int? maxParticipants; // Optional limit on participants
  bool isActive; // Whether current user has joined this event
  final DateTime createdAt;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.businessId,
    required this.businessName,
    required this.sportType,
    required this.startDate,
    required this.endDate,
    required this.participants,
    this.maxParticipants,
    this.isActive = false,
    required this.createdAt,
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

  String _getMonthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
