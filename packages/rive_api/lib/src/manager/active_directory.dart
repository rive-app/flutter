import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/view_model/view_model.dart';

class ActiveDirectoryManager {
  ActiveDirectoryManager() {
    //For testing purposes, just wiring up the
    // sink to push back out on stream
    _activeDirInput.stream.listen((dir) {
      if (_activeDirOutput.value != dir) _activeDirOutput.add(dir);
    });
  }

  /*
   * Outbound streams
   */

  final _dirsOutput = BehaviorSubject<DirectoryVM>();
  Stream<DirectoryVM> get dirsStream => _dirsOutput.stream;

  final _filesOutput = BehaviorSubject<Iterable<Stream<File>>>();
  Stream<Iterable<Stream<File>>> get fileStreams => _filesOutput.stream;

  /// The active directory can be set from the directory's sub-directories
  final _activeDirOutput = BehaviorSubject<DirectoryVM>();
  Stream<DirectoryVM> get activeDirStream => _activeDirOutput.stream;

  /*
   * Inbound sinks
   */

  final _activeDirInput = StreamController<DirectoryVM>();
  Sink<DirectoryVM> get activeDirSink => _activeDirInput;

  void dispose() {
    // Close all open file streams
    _filesOutput.value.forEach((s) => s.drain());
    _dirsOutput.close();
    _filesOutput.close();
    _activeDirInput.close();
  }
}
