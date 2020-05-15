import 'package:rive_api/plumber.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/api.dart';

class TeamManager with Subscriptions {
  static TeamManager _instance = TeamManager._();
  factory TeamManager() => _instance;

  TeamManager._() {
    _teamApi = TeamApi();
    _plumber = Plumber();
    _attach();
  }

  TeamManager.tester(TeamApi teamApi) {
    _teamApi = teamApi;
    _plumber = Plumber();
    _attach();
  }

  // Note: useful to cache this?
  List<Team> _teams;
  TeamApi _teamApi;
  Plumber _plumber;
  Me _lastMe;

  // For tests...
  void _attach() {
    subscribe<Me>(_handleNewMe);
  }

  void _handleNewMe(Me newMe) {
    if (_lastMe != newMe) {
      Plumber().flush<List<Team>>();
    }
    if (!newMe.isEmpty) {
      loadTeams();
    }
    _lastMe = newMe;
  }

  void loadTeams() async {
    final _teamsDM = await _teamApi.teams;
    _teams = Team.fromDMList(_teamsDM.toList());
    _plumber.message(_teams.toList());

    // asynchronoously go and load in some members
    _teams.forEach(loadTeamMembers);

    // if one of the teams we just loaded in
    // is currently selected, lets update that owner
    var _currentDirectory = _plumber.peek<CurrentDirectory>();
    if (_currentDirectory != null) {
      var _currentTeam = _teams.firstWhere(
          (element) => element.ownerId == _currentDirectory.owner.ownerId,
          orElse: () => null);
      if (_currentTeam != null) {
        _plumber.message(
            CurrentDirectory(_currentTeam, _currentDirectory.folderId));
      }
    }
  }

  void loadTeamMembers(Team team) async {
    final _teamMembersDM = await _teamApi.teamMembers(team.ownerId);
    final _teamMembers = TeamMember.fromDMList(_teamMembersDM.toList());
    _plumber.message(_teamMembers.toList(), team.hashCode);
  }
}
