class JoinedTeamsState {
  static final JoinedTeamsState _instance = JoinedTeamsState._internal();
  
  factory JoinedTeamsState() {
    return _instance;
  }
  
  JoinedTeamsState._internal() {
    // Add some sample teams that the user has already joined
    _initializeSampleTeams();
  }
  
  void _initializeSampleTeams() {
    // Add Running Club team
    final runningClub = {
      'name': 'Running Club',
      'description': 'Join us for morning runs and marathons',
      'category': 'Running',
      'members': '25',
    };
    _joinedTeamNames.add('Running Club');
    _joinedTeamsData['Running Club'] = runningClub;
    
    // Add swim team
    final swimTeam = {
      'name': 'swim',
      'description': 'Swimming enthusiasts welcome',
      'category': 'Swimming',
      'members': '18',
    };
    _joinedTeamNames.add('swim');
    _joinedTeamsData['swim'] = swimTeam;
  }
  
  final Set<String> _joinedTeamNames = {};
  final Map<String, Map<String, String>> _joinedTeamsData = {};
  
  // Check if a team is joined
  bool isTeamJoined(String teamName) {
    return _joinedTeamNames.contains(teamName);
  }
  
  // Join a team
  void joinTeam(Map<String, String> teamData) {
    final teamName = teamData['name']!;
    _joinedTeamNames.add(teamName);
    _joinedTeamsData[teamName] = Map.from(teamData);
  }
  
  // Leave a team
  void leaveTeam(String teamName) {
    _joinedTeamNames.remove(teamName);
    _joinedTeamsData.remove(teamName);
  }
  
  // Get all joined teams
  List<Map<String, String>> getAllJoinedTeams() {
    return _joinedTeamsData.values.toList();
  }
  
  // Get joined team names
  Set<String> getJoinedTeamNames() {
    return Set.from(_joinedTeamNames);
  }
  
  // Get a specific joined team data
  Map<String, String>? getTeamData(String teamName) {
    return _joinedTeamsData[teamName];
  }
  
  // Check if there are any joined teams
  bool hasJoinedTeams() {
    return _joinedTeamsData.isNotEmpty;
  }
}
