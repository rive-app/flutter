import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:rive_api/src/model/model.dart';

class ActiveDirectoryManager {
  ActiveDirectoryManager();

  /*
   * State
   */

  /// Track file streams
  Iterable<Stream<File>> _fileStreams;

  /*
   * Outbound streams
   */

  final _directoriesController = BehaviorSubject<Directory>();
  Stream<Directory> get directories => _directoriesController.stream;

  final _fileStreamsController = BehaviorSubject<Iterable<Stream<File>>>();
  Stream<Iterable<Stream<File>>> get fileStreams =>
      _fileStreamsController.stream;

  /*
   * Inbound sinks
   */

  final _activeDirectoryController = StreamController<Directory>();
  Sink<Directory> get activeDirectory => _activeDirectoryController;

  void dispose() {
    // Close all open file streams
    _fileStreamsController.value.forEach((s) => s.drain());
    _directoriesController.close();
    _fileStreamsController.close();
    _activeDirectoryController.close();
  }
}
