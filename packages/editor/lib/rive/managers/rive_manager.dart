import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/rive.dart';

/// General manager for general ui things
class RiveManager with Subscriptions {
  static final RiveManager _instance = RiveManager._();
  factory RiveManager() => _instance;

  RiveManager._() {
    _attach();
  }
  RiveManager.tester() {
    _attach();
  }

  void _attach() {
    subscribe<HomeSection>(_newHomeSection);
    subscribe<CurrentDirectory>(_newCurrentDirectory);
  }

  /// Initiatize the state
  void _newHomeSection(HomeSection newHomeSection) {
    // Handle incoming team invitation acceptances
    if (newHomeSection != HomeSection.files) {
      Plumber().flush<CurrentDirectory>();
    }
  }

  void _newCurrentDirectory(CurrentDirectory currentDirectory) {
    // Handle incoming team invitation acceptances
    if (currentDirectory != null) {
      if (Plumber().peek<HomeSection>() != HomeSection.files) {
        Plumber().message(HomeSection.files);
      }
    }
  }

  void viewTeam(int teamOwnerId) {
    // NOTE: you hit this, without having loaded the team
    // this will obviously fail.
    var _plumber = Plumber();
    var teams = _plumber.peek<List<Team>>();
    var targetTeam =
        teams.firstWhere((element) => element.ownerId == teamOwnerId);
    // 1 is the magic base folder
    _plumber.message(CurrentDirectory(targetTeam, 1));
  }
}
