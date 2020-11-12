import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/plumber.dart';

class TeamManager with Subscriptions {
  static final TeamManager _instance = TeamManager._();
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
    if (newMe != null && !newMe.isEmpty) {
      loadTeams();
    }
    _lastMe = newMe;
  }

  Future<void> loadTeams() async {
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
        _plumber.message(CurrentDirectory(
          _currentTeam,
          _currentDirectory.folder,
        ));
      }
    }
  }

  Future<void> loadTeamMembers(Team team) async {
    final _teamMembersDM = await _teamApi.teamMembers(team.ownerId);
    final _teamMembers = TeamMember.fromDMList(_teamMembersDM.toList());
    _plumber.message<List<TeamMember>>(_teamMembers.toList(), team.hashCode);
  }

  Future<bool> onInviteChanged(
      Team team, TeamMember member, TeamRole role) async {
    bool success = false;
    String email = member.ownerId <= 0 ? member.name : null;
    if (role == TeamRole.delete) {
      success = await _teamApi.rescindInvite(team.ownerId,
          ownerId: member.ownerId, email: email);
    } else {
      success = await _teamApi.updateInvite(team.ownerId, role,
          ownerId: member.ownerId, email: email);
    }
    if (success) {
      // Clean up stale data.
      _plumber.flush<List<TeamMember>>(team.hashCode);
    }
    return success;
  }

  Future<bool> onRoleChanged(
      Team team, int memberOwnerId, TeamRole role) async {
    bool success = false;
    if (role == TeamRole.delete) {
      success = await _teamApi.removeFromTeam(memberOwnerId, team.ownerId);
    } else {
      success = await _teamApi.changeRole(team.ownerId, memberOwnerId, role);
    }
    if (success) {
      // Clean up stale data.
      _plumber.flush<List<TeamMember>>(team.hashCode);
    }
    return success;
  }

  Future<bool> saveToken(Team team, String token) async =>
      _teamApi.saveToken(team.ownerId, token);

  Future<Team> createTeam(String teamName, String plan, String frequency,
      String stripeToken) async {
    var teamDM =
        await _teamApi.createTeam(teamName, plan, frequency, stripeToken);
    await loadTeams();
    var team = Team.fromDM(teamDM);
    await FileManager().loadBaseFolder(team);
    return Team.fromDM(teamDM);
  }

  Future<void> getCharges(Team team) async {
    final detailsDM = await _teamApi.getBillingHistory(team.ownerId);
    final details = BillingDetails.fromDM(detailsDM);
    _plumber.message<BillingDetails>(details, team.hashCode);
  }

  Future<bool> setBillingDetails(Team team, BillingDetails details) async {
    bool success = await _teamApi.setBillingDetails(team.ownerId, details);
    if (success) {
      // Update the pipes.
      _plumber.message<BillingDetails>(details, team.hashCode);
    }

    return true;
  }

  Future<void> delete(Team team, String password) async {
    await _teamApi.deleteApi(team.ownerId, password);
    // ok, if we're currently got the team selected, lets select the user
    var _currentDirectory = _plumber.peek<CurrentDirectory>();

    if (_currentDirectory.owner.ownerId == team.ownerId) {
      var _me = _plumber.peek<Me>();
      _plumber.message(CurrentDirectory(
          _me,
          Folder(
              id: -1,
              ownerId: _me.ownerId,
              name: null,
              parent: null,
              order: -1)));
    }
    // reload teams!
    await loadTeams();
  }
}
