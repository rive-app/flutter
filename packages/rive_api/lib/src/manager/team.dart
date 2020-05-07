import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/plumber.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';

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
      Plumber().clear<List<Team>>();
    }
    if (newMe != null) {
      loadTeams();
    }
    _lastMe = newMe;
  }

  void loadTeams() async {
    final _teamsDM = await _teamApi.teams;
    _teams = Team.fromDMList(_teamsDM.toList());
    _plumber.message(_teams.toList());
  }
}
