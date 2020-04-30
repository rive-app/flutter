import 'dart:async';

import 'package:meta/meta.dart';
import 'package:async/async.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/view_model/view_model.dart';

/// Wires the different managers together

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
    final streams = [
      // volumeManager.activeDirStream,
      activeDirManager.activeDirStream,
    ];
    final sinks = [
      volumeManager.activeDirSink,
      activeDirManager.activeDirSink,
      activeDirSink,
    ];

    final groupedStreams = StreamGroup<Directory>.broadcast();
    streams.forEach((s) => groupedStreams.add(s));

    /// Add any inbound dirs to the outbound sinks
    groupedStreams.stream.listen((d) {
      sinks.forEach((s) => s.add(d));
    });
  }
}
