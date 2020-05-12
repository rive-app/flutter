import 'dart:async';
import 'package:rive_editor/rive/rive.dart';

/// Bit of a placeholder as I didnt want to throw rive into other managers.
class RiveManager {
  final Rive rive;
  RiveManager(this.rive) {
    _init();
  }

  /*
   * Inbound sinks
   */

  /// Inbound acceptance of a team invite
  final _teamUpdateSinkController = StreamController<bool>.broadcast();
  Sink<bool> get teamUpdateSink => _teamUpdateSinkController;

  /// Clean up all the stream controllers and that polling timer
  void dispose() {
    _teamUpdateSinkController.close();
  }

  /*
   * State
   */

  /// Initiatize the state
  void _init() {
    // Handle incoming team invitation acceptances
    _teamUpdateSinkController.stream.listen(_reloadTeams);
  }

  /// Removes a notification from the list
  void _reloadTeams(bool reload) {
    print('yea..... shoudl reload teams or something');
    // rive.reloadTeams();
  }
}
