import 'dart:async';

import 'package:meta/meta.dart';

import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/view_model/view_model.dart';

/// Conductor is the manager of managers, or be more precise,
/// the thing that wires all the sinks and streams together, so
/// we don't have to do it all over the UI code.
///
/// We could just stick the conductor in an inherited widget,
/// and use it to get references to any of the managers.
///
/// We could also expose all the sinks (inbound data) in the conductor,
/// and then let the conductor route it. Or we can listen to the appropriate
/// manager streams.
class Conductor {
  Conductor({@required this.volumeManager, @required this.activeDirManager})
      : assert(volumeManager != null),
        assert(activeDirManager != null) {
    _wireActiveDirectory();
  }
  final VolumeManager volumeManager;
  final ActiveDirectoryManager activeDirManager;

  // Adding a route in to change the active directory
  // We could remove the inbound sinks in all the managers
  // and just use the conductor as the sole sink for
  // active directory changes. Leaving them all in for
  // the moment pending a decision.

  final _activeDirectoryInput = StreamController<DirectoryVM>();
  Sink<DirectoryVM> get activeDirSink => _activeDirectoryInput;

  /// Wires up the sinks/streams for active directory
  void _wireActiveDirectory() {
    // External sinks
    final externalSinks = [
      volumeManager.activeDirSink,
      activeDirManager.activeDirSink,
    ];

    // Handle inbound active directory change
    // from the active dir manager
    // Beware circular sinks/streams infinite loops
    activeDirManager.activeDirStream.listen((d) {
      externalSinks
          .where((s) => s != activeDirManager.activeDirSink)
          .forEach((s) => s.add(d));
    });

    // Handle inbound active directory change
    _activeDirectoryInput.stream.listen((d) {
      externalSinks.forEach((s) => s.add(d));
    });
  }
}
