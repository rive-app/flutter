import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rive_api/src/api/api.dart';

class VolumeManager {
  VolumeManager({MeApi meApi, VolumeApi volumeApi})
      : _volApi = volumeApi ?? VolumeApi(),
        _meApi = meApi ?? MeApi() {
    _volumesOutput.onListen = _fetchVolumes;
    _activeDirectoryInput.stream.listen(_handleActiveDirInput);
  }
  final MeApi _meApi;
  final VolumeApi _volApi;

  /*
   * State
   */

  /// Directory trees for volumes by their ids
  final _trees = <int, DirectoryTree>{};

  /// Tree streams for volumes by their ids
  final _treeOutputs = <int, BehaviorSubject<DirectoryTreeVM>>{};

  DirectoryVM _activeDirectory;

  /*
   * Inbound sinks
   */

  final _activeDirectoryInput = StreamController<DirectoryVM>();
  Sink<DirectoryVM> get activeDirSink => _activeDirectoryInput;
  _handleActiveDirInput(DirectoryVM dir) {
    _activeDirectory = dir;
    // Loop through all of the loaded directory trees. If any contain
    // the active directory,
    // output a new DirectoryTreeVM with the AD included. If any
    // other dir tree has an active dir, output a new DirectoryTreeVM
    // with the AD removed.
    _trees.forEach(_updateActiveDirectory);
  }

  /*
   * Outbound streams
   */

  final _volumesOutput = BehaviorSubject<Iterable<VolumeVM>>();
  Stream<Iterable<VolumeVM>> get volumesStream => _volumesOutput.stream;

  /*
   * API interface
   */

  void _fetchVolumes() async {
    // Fetch the data
    final me = await _meApi.whoami;
    final teams = await _volApi.teams;
    // Create the output tree controllers
    _treeOutputs[me.ownerId] = BehaviorSubject<DirectoryTreeVM>();
    _treeOutputs[me.ownerId].onListen = () async {
      final tree = await _fetchDirectoryTree(VolumeType.user);
      _trees[me.ownerId] = tree;
      _treeOutputs[me.ownerId].add(DirectoryTreeVM.fromModel(tree));
      if (_activeDirectory != null) {
        _updateActiveDirectory(me.ownerId, tree);
      }
    };
    teams.forEach((team) {
      _treeOutputs[team.ownerId] = BehaviorSubject<DirectoryTreeVM>();
      // Load the directory tree when this is listened to
      _treeOutputs[team.ownerId].onListen = () async {
        final tree = await _fetchDirectoryTree(VolumeType.team, team.ownerId);
        _trees[team.ownerId] = tree;
        _treeOutputs[team.ownerId].add(DirectoryTreeVM.fromModel(tree));
        if (_activeDirectory != null) {
          _updateActiveDirectory(team.ownerId, tree);
        }
      };
    });
    // Create the volume view models
    _volumesOutput.add(
      []
        ..add(VolumeVM.fromMeModel(me, _treeOutputs[me.ownerId]))
        ..addAll(
          teams.map(
            (t) => VolumeVM.fromTeamModel(t, _treeOutputs[t.ownerId]),
          ),
        ),
    );
    // Ensure that any set active directory is now propagated through the
    // tree streams
    if (_activeDirectory != null) {
      _handleActiveDirInput(_activeDirectory);
    }
  }

  Future<DirectoryTree> _fetchDirectoryTree(VolumeType volumeType,
          [int id]) async =>
      await volumeType == VolumeType.user
          ? _volApi.directoryTreeMe
          : _volApi.directoryTreeTeam(id);

/*
 * Functions
 */

  void dispose() {
    _treeOutputs.values.forEach((s) => s.close());
    _activeDirectoryInput.close();
    _volumesOutput.close();
  }

  void _updateActiveDirectory(int id, DirectoryTree tree) {
    if (tree.contains(DirectoryVM.toModel(_activeDirectory))) {
      _treeOutputs[id].add(DirectoryTreeVM.fromModel(tree, _activeDirectory));
    } else if (_treeOutputs[id].value.activeDirectory != null) {
      _treeOutputs[id].add(DirectoryTreeVM.fromModel(tree));
    }
  }
}
