import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rive_api/src/api/api.dart';

class VolumeManager {
  VolumeManager([VolumeApi api]) : _api = api ?? VolumeApi() {
    _volumesOutput.onListen = _fetchVolumes;
    _activeDirectoryInput.stream.listen(_handleActiveDirInput);
  }
  final VolumeApi _api;

  /*
   * State
   */

  /// Directory trees for volumes
  final _trees = <Volume, DirectoryTree>{};

  /// Tree streams
  final _treeOutputs = <Volume, BehaviorSubject<DirectoryTreeVM>>{};

  /*
   * Inbound sinks
   */

  final _activeDirectoryInput = StreamController<DirectoryVM>();
  Sink<DirectoryVM> get activeDirSink => _activeDirectoryInput;
  _handleActiveDirInput(DirectoryVM dir) {
    // Loop through all of the directory trees. If any contain
    // the active directory,
    // output a new DirectoryTreeVM with the AD included. If any
    // other dir tree has an active dir, output a new DirectoryTreeVM
    // with the AD removed.
    _trees.forEach((volume, tree) {
      if (tree.contains(DirectoryVM.toModel(dir))) {
        _treeOutputs[volume].add(DirectoryTreeVM.fromModel(tree, dir));
      } else if (_treeOutputs[volume].value.activeDirectory != null) {
        _treeOutputs[volume].add(DirectoryTreeVM.fromModel(tree));
      }
    });
  }

  /*
   * Outbound streams
   */

  final _volumesOutput = BehaviorSubject<Iterable<VolumeVM>>();
  Stream<Iterable<VolumeVM>> get volumesStream => _volumesOutput.stream;

  void dispose() {
    _treeOutputs.values.forEach((s) => s.close());
    _activeDirectoryInput.close();
    _volumesOutput.close();
  }

  /*
   * API interface
   */

  void _fetchVolumes() async {
    final volumes = (await _api.volumes).toList();
    // Create the output tree controllers
    for (final volume in volumes) {
      _treeOutputs[volume] = BehaviorSubject<DirectoryTreeVM>();
      // Load the directory tree when this is listened to
      _treeOutputs[volume].onListen = () async {
        final tree = await _fetchDirectoryTree(volume);
        _trees[volume] = tree;
        _treeOutputs[volume].add(DirectoryTreeVM.fromModel(tree));
      };
    }
    // Create the volume view models
    _volumesOutput.add(
      volumes.map((v) => VolumeVM.fromModelWithStream(v, _treeOutputs[v])),
    );
  }

  Future<DirectoryTree> _fetchDirectoryTree(Volume volume) async =>
      await _api.directoryTree(volume);
}
