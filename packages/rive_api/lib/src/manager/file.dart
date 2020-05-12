import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/plumber.dart';

class FileManager with Subscriptions {
  static FileManager _instance = FileManager._();
  factory FileManager() => _instance;

  FileManager._()
      : _fileApi = FileApi(),
        _folderApi = FolderApi() {
    subscribe<Me>(_handleNewMe);
    subscribe<List<Team>>(_handleNewTeams);
  }

  final FolderApi _folderApi;
  final FileApi _fileApi;
  Me _me;

  final _folderMap = Map<Owner, List<Folder>>();
  final _fileMap = Map<Folder, List<File>>();

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
    Plumber().message(_folders, owner.hashCode);
    _updateFolderList();
  }

  void _updateFolderList() {
    Plumber().message(_folderMap);
  }

  void _clearFolderList() {
    _folderMap.clear();
    Plumber().flush<Map<Owner, List<Folder>>>();
  }

  void loadFiles(Folder folder, Owner owner) async {
    List<File> _files;
    if (owner is Me) {
      _files =
          File.fromDMList(await _fileApi.myFiles(owner.ownerId, folder.id));
    } else {
      _files =
          File.fromDMList(await _fileApi.teamFiles(owner.ownerId, folder.id));
    }

    _fileMap[folder] = _files;
  }
}

class SelectedFile extends File {}
