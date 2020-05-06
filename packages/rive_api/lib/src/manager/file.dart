import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/plumber.dart';

class FileManager with Subscriptions {
  FileManager() {
    _fileApi = FileApi();
    _folderApi = FolderApi();
    _plumber = Plumber();
    subscribe<Me>(_handleNewMe);
    subscribe<Iterable<Team>>(_handleNewTeams);
  }

  FolderApi _folderApi;
  FileApi _fileApi;
  Plumber _plumber;
  Me _me;

  Map _folderMap = Map<Owner, Iterable<Folder>>();
  Map _fileMap = Map<Folder, Iterable<File>>();

  void _handleNewMe(Me me) {
    _clearFolderList();
    loadFolders(me);
  }

  void _handleNewTeams(Iterable<Team> teams) {
    // lets ditch teams no longer reported.
    // for owners in _folderMap.keys {
    //   if owner not in
    // }
    teams.forEach((team) {
      loadFolders(team);
    });
  }

  void loadFolders(Owner owner) async {
    final _folders = Folder.fromDMList(await _folderApi.folders(owner.asDM));
    _folderMap[owner] = _folders;
    _updateFolderList();
  }

  void _updateFolderList() {
    _plumber.message(_folderMap);
  }

  void _clearFolderList() {
    _folderMap.clear();
    _plumber.clear<Map<Owner, Iterable<Folder>>>();
  }

  void loadFiles(Folder folder) async {
    final _files = File.fromDMList(await _fileApi.getFiles(folder.asDM));
    _fileMap[folder] = _files;
  }
}

class SelectedFile extends File {}
