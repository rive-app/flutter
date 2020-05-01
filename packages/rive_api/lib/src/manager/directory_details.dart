import 'dart:async';

import 'package:rive_api/src/api/file.dart';
import 'package:rxdart/rxdart.dart';

import 'package:rive_api/src/view_model/view_model.dart';

class DirectoryDetailsManager {
  DirectoryDetailsManager({
    BehaviorSubject<DirectoryVM> activeDirController,
    BehaviorSubject<Iterable<FileVM>> activeDirectoryFilesController,
    FileApi fileApi,
  })  : _activeDirectoryFilesController = activeDirectoryFilesController,
        _activeDirectoryInput = activeDirController,
        _fileApi = fileApi ?? FileApi() {
    activeDirController.stream.listen(_handleActiveDirInput);
  }
  final FileApi _fileApi;

  /*
   * State
   */

  final directoryFileCache = Map<int, Iterable<FileVM>>();

  /*
   * Inbound sinks
   */

  final _activeDirectoryInput;
  Sink<DirectoryVM> get activeDirSink => _activeDirectoryInput;
  _handleActiveDirInput(DirectoryVM dir) {
    if (dir == null) {
      _activeDirectoryFilesController.add(null);
    } else {
      if (!directoryFileCache.containsKey(dir.id)) {
        directoryFileCache[dir.id] = List<FileVM>();
      }
      print('here?');
      _activeDirectoryFilesController.add(directoryFileCache[dir.id]);
      _fetchDirectoryFiles(dir);
    }
  }

  /*
   * Outbound streams
   */

  final BehaviorSubject<Iterable<FileVM>> _activeDirectoryFilesController;
  Stream<Iterable<FileVM>> get filesStream =>
      _activeDirectoryFilesController.stream;

  /*
   * API interface
   */

  void _fetchDirectoryFiles(DirectoryVM dir) async {
    print('fetching?');
    // Fetch the data
    final files = await _fileApi.getFiles(dir);
    directoryFileCache[dir.id] =
        files.map((file) => FileVM.fromModel(file)).toList();
    _activeDirectoryFilesController.add(directoryFileCache[dir.id]);
  }
}
