class TeamState {
  static final TeamState _instance = TeamState._internal();
  factory TeamState() => _instance;
  TeamState._internal();

  Map<String, String>? _createdTeam;

  Map<String, String>? get createdTeam => _createdTeam;

  void setTeam(Map<String, String> teamData) {
    _createdTeam = Map.from(teamData);
  }

  void updateTeam(Map<String, String> teamData) {
    _createdTeam = Map.from(teamData);
  }

  void deleteTeam() {
    _createdTeam = null;
  }

  bool hasTeam() {
    return _createdTeam != null;
  }
}
