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

  final _dirsOutput = BehaviorSubject<Directory>();
  Stream<Directory> get dirsStream => _dirsOutput.stream;

  final _filesOutput = BehaviorSubject<Iterable<Stream<File>>>();
  Stream<Iterable<Stream<File>>> get fileStreams => _filesOutput.stream;

  /// The active directory can be set from the directory's sub-directories
  final _activeDirOutput = BehaviorSubject<Directory>();
  Stream<Directory> get activeDirStream => _activeDirOutput.stream;

  /*
   * Inbound sinks
   */

  final _activeDirInput = StreamController<Directory>();
  Sink<Directory> get activeDirSink => _activeDirInput;

  void dispose() {
    // Close all open file streams
    _filesOutput.value.forEach((s) => s.drain());
    _dirsOutput.close();
    _filesOutput.close();
    _activeDirInput.close();
  }
}
