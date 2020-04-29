import 'dart:async';

import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/directory_tree.dart';
import 'package:rxdart/rxdart.dart';

class DirectoryTreeManager {
  DirectoryTreeManager(this.volume, [DirectoryTreeApi api])
      : _api = api ?? DirectoryTreeApi() {
    // Fetch user details when stream is first listened to
    _treeController.onListen = _fetchDirectoryTree;

    // Record all inbound events for directory selection
    _activeDirectoryController.stream.listen((dir) => _activeDirectory = dir);
  }
  final DirectoryTreeApi _api;
  final Volume volume;
  /*
   * State
   */
  DirectoryTree __directoryTree;
  void set _directoryTree(DirectoryTree tree) {
    _directoryTree = tree;
    _treeController.add(tree);
  }

  Directory _activeDirectory;

  /*
   * Outbound streams
   */

  final _treeController = BehaviorSubject<DirectoryTree>();
  Stream<DirectoryTree> get tree => _treeController.stream;

  /*
   * Inbound sinks
   */
  final _activeDirectoryController = StreamController<Directory>();
  Sink<Directory> get activeDirectory => _activeDirectoryController;

  void dispose() => _treeController.close();

  /*
   * API interface
   */

  void _fetchDirectoryTree() async =>
      _directoryTree = await _api.directoryTree(volume);
}
