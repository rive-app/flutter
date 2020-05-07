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
    subscribe<Me>(_handleNewMe);
  }

  // Note: useful to cache this?
  List<Team> _teams;
  TeamApi _teamApi;
  Plumber _plumber;

  void _handleNewMe(Me me) {
    Plumber().clear<List<Team>>();
    loadTeams();
  }

  void loadTeams() async {
    final _teamsDM = await _teamApi.teams;
    _teams = Team.fromDMList(_teamsDM.toList());
    _plumber.message(_teams.toList());
  }
}
