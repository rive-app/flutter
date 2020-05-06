import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/plumber.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';

class TeamManager with Subscriptions {
  TeamManager() {
    _teamApi = TeamApi();
    _plumber = Plumber();
    subscribe<Me>(_handleNewMe);
  }

  // Note: useful to cache this?
  Iterable<Team> _teams;
  TeamApi _teamApi;
  Plumber _plumber;

  void _handleNewMe(Me me) {
    Plumber().clear<Iterable<Team>>();
    loadTeams();
  }

  void loadTeams() async {
    _teams = Team.fromDMList(await _teamApi.teams);
    _plumber.message(_teams);
  }
}
