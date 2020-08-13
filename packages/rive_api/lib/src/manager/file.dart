import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/plumber.dart';
import 'package:utilities/utilities.dart';

class FileManager with Subscriptions {
  static final _instance = FileManager._();
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

  final _folderMap = <Owner, List<Folder>>{};
  final _fileMap = <Folder, List<File>>{};

  void _handleNewMe(Me me) {
    if (_me != me) {
      _clearFolderList();
    }
    _me = me;
    if (_me == null || _me.isEmpty) {
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

    teams?.forEach(loadFolders);
  }

  Future<File> createFile(Owner owner, [Folder folder]) async {
    var _folder = (folder == null)
        ? _folderMap[owner].firstWhere((element) => element.id == 1)
        : folder;
    FileDM fileDM;
    if (owner is Team) {
      fileDM = await _fileApi.createFile(_folder.id, _folder.ownerId);
    } else {
      fileDM = await _fileApi.createFile(_folder.id);
    }

    return File.fromDM(fileDM, owner.ownerId);
  }

  Future<Folder> createFolder(Owner owner, [Folder folder]) async {
    folder ??= _folderMap[owner].firstWhere((element) => element.id == 1);
    FolderDM folderDM;
    if (owner is Team) {
      folderDM = await _folderApi.createTeamFolder(folder.id, folder.ownerId);
    } else {
      folderDM =
          await _folderApi.createPersonalFolder(folder.id, folder.ownerId);
    }

    return Folder.fromDM(folderDM);
  }

  Future<void> loadFolders(Owner owner) async {
    final _foldersDM = await _folderApi.folders(owner.asDM);
    final _folders = Folder.fromDMList(_foldersDM.toList());
    _folderMap[owner] = _folders;
    _plumber.message(_folders, owner.hashCode);
    _updateFolderList();
  }

  void _updateFolderList() => _plumber.message(_folderMap);

  void _clearFolderList() {
    _folderMap.keys
        .forEach((key) => _plumber.flush<List<Folder>>(key.hashCode));
    _folderMap.clear();
    _plumber.flush<Map<Owner, List<Folder>>>();
  }

  Future<void> loadFiles(Folder folder, Owner owner) async {
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

  /// Load in the user's recent files details
  Future<Iterable<File>> loadRecentFilesDetails() async {
    final fileDataModels = await _fileApi.recentFilesDetails();
    final files = File.fromDMList(fileDataModels);
    // Place the file details into the caching file details streams
    // TODO: these should be hashed with the hashed id, not int
    files.forEach((file) =>
        Plumber().message<File>(file, szudzik(file.id, file.ownerId)));

    return files;
  }

  /// Save the file name. This involves not only passing the new
  /// file name to the backend via the api, but also updating the
  /// file data in the stream, allowing the file browser to update.
  Future<void> renameFile(File file, String name) async {
    // if me's not set you have other problems.
    final changed = (_me != null && _me.ownerId == file.fileOwnerId)
        ? await _fileApi.renameMyFile(file.fileOwnerId, file.id, name)
        : await _fileApi.renameProjectFile(file.fileOwnerId, file.id, name);
    if (changed) {
      File updatedFile = File(
        id: file.id,
        name: name,
        ownerId: file.ownerId,
        fileOwnerId: file.fileOwnerId,
        preview: file.preview,
      );

      Plumber().message<File>(updatedFile);
    }
  }

  void loadParentFolder(CurrentDirectory currentDirectory) {
    final targetFolder = _folderMap[currentDirectory.owner].firstWhere(
      (element) => element.id == currentDirectory.folder.parent,
      orElse: () {
        return _folderMap[currentDirectory.owner]
            .firstWhere((folder) => folder.id == 1);
      },
    );
    Plumber().message(CurrentDirectory(currentDirectory.owner, targetFolder));
  }

  void loadBaseFolder(Owner owner) {
    final backupFolder = Folder(
      id: 1,
      name: 'unknown',
      parent: null,
      order: 1,
      ownerId: owner.ownerId,
    );
    final targetFolder = (_folderMap[owner] == null)
        ? backupFolder
        : _folderMap[owner].firstWhere(
            (folder) => folder.id == 1,
            orElse: () {
              return backupFolder;
            },
          );
    Plumber().message(CurrentDirectory(owner, targetFolder));
  }
}
