import 'package:flutter/foundation.dart';

class JoinedEventsState extends ChangeNotifier {
  static final JoinedEventsState _instance = JoinedEventsState._internal();
  factory JoinedEventsState() => _instance;
  JoinedEventsState._internal();

  final Set<String> _joinedEventIds = <String>{};

  Set<String> get joinedEventIds => Set.unmodifiable(_joinedEventIds);

  bool isEventJoined(String eventId) {
    return _joinedEventIds.contains(eventId);
  }

  void joinEvent(String eventId) {
    if (!_joinedEventIds.contains(eventId)) {
      _joinedEventIds.add(eventId);
      notifyListeners();
    }
  }

  void leaveEvent(String eventId) {
    if (_joinedEventIds.contains(eventId)) {
      _joinedEventIds.remove(eventId);
      notifyListeners();
    }
  }

  void clearAllJoinedEvents() {
    _joinedEventIds.clear();
    notifyListeners();
  }
}
