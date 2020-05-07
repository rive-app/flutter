import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/plumber.dart';

class FileManager with Subscriptions {
  static FileManager _instance = FileManager._();
  factory FileManager() => _instance;

  FileManager._() {
    _fileApi = FileApi();
    _folderApi = FolderApi();
    _plumber = Plumber();
    subscribe<Me>(_handleNewMe);
    subscribe<List<Team>>(_handleNewTeams);
  }

  FolderApi _folderApi;
  FileApi _fileApi;
  Plumber _plumber;
  Me _me;

  Map<Owner, List<Folder>> _folderMap = Map<Owner, List<Folder>>();
  Map<Folder, List<File>> _fileMap = Map<Folder, List<File>>();

  void _handleNewMe(Me me) {
    _me = me;
    _clearFolderList();
    loadFolders(me);
  }

  void _handleNewTeams(List<Team> teams) {
    // lets ditch teams no longer reported.
    Set<Owner> removeKeys = {};
    _folderMap.keys?.forEach((folderOwner) {
      if ((teams != null && teams.contains(folderOwner)) ||
          _me == folderOwner) {
        // move along folders good.
      } else {
        removeKeys.add(folderOwner);
      }
    });
    removeKeys.forEach((key) {
      _folderMap.remove(key);
    });
    _updateFolderList();

    teams?.forEach((team) {
      loadFolders(team);
    });
  }

  void loadFolders(Owner owner) async {
    final _foldersDM = await _folderApi.folders(owner.asDM);
    final _folders = Folder.fromDMList(_foldersDM.toList());
    _folderMap[owner] = _folders;
    _updateFolderList();
  }

  void _updateFolderList() {
    _plumber.message(_folderMap);
  }

  void _clearFolderList() {
    _folderMap.clear();
    _plumber.clear<Map<Owner, List<Folder>>>();
  }

  void loadFiles(Folder folder) async {
    final _files = File.fromDMList(await _fileApi.getFiles(folder.asDM));
    _fileMap[folder] = _files;
  }
}

class SelectedFile extends File {}
