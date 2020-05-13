import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/plumber.dart';

class FileManager with Subscriptions {
  static FileManager _instance = FileManager._();
  factory FileManager() => _instance;

  FileManager._()
      : _fileApi = FileApi(),
        _folderApi = FolderApi(),
        _plumber = Plumber() {
    subscribe<Me>(_handleNewMe);
    subscribe<List<Team>>(_handleNewTeams);
  }

  FileManager.tester(FileApi fileApi, FolderApi folderApi) {
    _fileApi = fileApi;
    _folderApi = folderApi;
    _plumber = Plumber();
    _attach();
  }

  void _attach() {
    subscribe<Me>(_handleNewMe);
    subscribe<List<Team>>(_handleNewTeams);
  }

  FolderApi _folderApi;
  FileApi _fileApi;
  Plumber _plumber;
  Me _me;

  final _folderMap = Map<Owner, List<Folder>>();
  final _fileMap = Map<Folder, List<File>>();

  void _handleNewMe(Me me) {
    if (_me != me) {
      _clearFolderList();
    }
    _me = me;
    if (_me.isEmpty) {
      return;
    }

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
      _plumber.flush<List<Folder>>(key.hashCode);
      _folderMap.remove(key);
    });
    _updateFolderList();

    teams?.forEach((team) {
      loadFolders(team);
    });
  }

  Future<File> createFile(int folderId, [int teamId]) async {
    final fileDM = await _fileApi.createFile(folderId, teamId);
    return File.fromDM(fileDM);
  }

  Future<Folder> createFolder(int folderId, [int teamId]) async {
    final folderDM = await _folderApi.createFolder(folderId, teamId);
    return Folder.fromDM(folderDM);
  }

  void loadFolders(Owner owner) async {
    final _foldersDM = await _folderApi.folders(owner.asDM);
    final _folders = Folder.fromDMList(_foldersDM.toList());
    _folderMap[owner] = _folders;
    _plumber.message(_folders, owner.hashCode);
    _updateFolderList();
  }

  void _updateFolderList() {
    _plumber.message(_folderMap);
  }

  void _clearFolderList() {
    _folderMap.keys
        .forEach((key) => _plumber.flush<List<Folder>>(key.hashCode));
    _folderMap.clear();
    _plumber.flush<Map<Owner, List<Folder>>>();
  }

  void loadFiles(Folder folder, Owner owner) async {
    // currently unused.
    List<File> _files;
    if (owner is Me) {
      _files =
          File.fromDMList(await _fileApi.myFiles(owner.ownerId, folder.id));
    } else {
      _files = File.fromDMList(
          await _fileApi.teamFiles(owner.ownerId, folder.id), owner.ownerId);
    }

    _fileMap[folder] = _files;
    _plumber.message(_files, folder.hashCode);
  }
}
