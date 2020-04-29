import 'dart:async';

import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/directory_tree.dart';
import 'package:rxdart/rxdart.dart';

class DirectoryTreeManager {
  DirectoryTreeManager(this.volume, [DirectoryTreeApi api])
      : _api = api ?? DirectoryTreeApi() {
    // Fetch user details when stream is first listened to
    _treeOutput.onListen = _fetchDirectoryTree;
    // Setup input handlers
    _handleActiveDirInput();
  }
  final DirectoryTreeApi _api;
  final Volume volume;

  /*
   * State
   */

  DirectoryTree __directoryTree;
  void set _directoryTree(DirectoryTree tree) {
    _directoryTree = tree;
    _treeOutput.add(tree);
  }

  /*
   * Outbound streams
   */

  final _treeOutput = BehaviorSubject<DirectoryTree>();
  Stream<DirectoryTree> get tree => _treeOutput.stream;

  final _activeDirOutput = BehaviorSubject<Directory>();
  Stream<DirectoryTree> get activeDirStream => _treeOutput.stream;

  /*
   * Inbound sinks
   */

  final _activeDirInput = StreamController<Directory>();
  Sink<Directory> get activeDirSink => _activeDirInput;
  _handleActiveDirInput() {
    // Handle incoming active directory events
    _activeDirInput.stream.listen((dir) {
      // If the directory is in the tree, output it
      if (__directoryTree.contains(dir)) {
        _activeDirOutput.add(dir);
      }
    });
  }

  void dispose() => _treeOutput.close();

  /*
   * API interface
   */

  void _fetchDirectoryTree() async =>
      _directoryTree = await _api.directoryTree(volume);
}
