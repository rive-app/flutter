import 'dart:async';
import 'dart:collection';

import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/plumber.dart';

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
    FileDM fileDM = await _fileApi.createFile(owner.ownerId, folder?.id);

    return File.fromDM(fileDM, owner.ownerId);
  }

  Future<Folder> createFolder(Owner owner, [Folder folder]) async {
    FolderDM folderDM =
        await _folderApi.createFolder(owner.ownerId, folder?.id);

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
    List<File> _files =
        File.fromDMList(await _fileApi.files(owner.ownerId, folder.id));

    _fileMap[folder] = _files;
    _plumber.message(_files, folder.hashCode);
  }

  /// Load in the user's recent files details
  Future<Iterable<File>> loadRecentFiles() async {
    final fileDataModels = await _fileApi.recentFiles();
    final files = File.fromDMList(fileDataModels);
    final plumber = Plumber();
    files.forEach((file) {
      var cached = cachedDetails(file.id);
      if (cached != null) {
        plumber.message<File>(cached, cached.hashCode);
      } else {
        plumber.message<File>(file, file.hashCode);
      }
    });

    return files;
  }

  /// Save the file name. This involves not only passing the new
  /// file name to the backend via the api, but also updating the
  /// file data in the stream, allowing the file browser to update.
  Future<void> renameFile(File file, String name) async {
    // if me's not set you have other problems.
    final changed = await _fileApi.renameFile(file.id, name);
    if (changed) {
      File updatedFile = File(
        id: file.id,
        name: name,
        ownerId: file.ownerId,
        fileOwnerId: file.fileOwnerId,
        thumbnail: file.thumbnail,
      );
      _detailsCache[file.id] = _DetailsCacheEntry(updatedFile);

      Plumber().message<File>(updatedFile);
    }
  }

  void loadParentFolder(CurrentDirectory currentDirectory) {
    final targetFolder = _folderMap[currentDirectory.owner].firstWhere(
      (element) => element.id == currentDirectory.folder.parent,
      orElse: () {
        return null;
      },
    );
    Plumber().message(CurrentDirectory(currentDirectory.owner, targetFolder));
  }

  Future<void> loadBaseFolder(Owner owner) async {
    if (_folderMap[owner] == null) {
      await loadFolders(owner);
    }

    Plumber().message(CurrentDirectory(
        owner,
        Folder(
          id: -1,
          name: null,
          parent: null,
          order: -1,
          ownerId: owner.ownerId,
        )));
  }

  final _detailsBatch = HashSet<File>();
  Timer _loadDetailsTimer;

  /// Let the manager know the details for this file are necessary, get schedule
  /// fetching them (we delay so we can batch and debounce when scrolling
  /// through lots of content).
  void needDetails(File file) {
    _detailsBatch.add(file);

    _loadDetailsTimer ??=
        Timer(const Duration(milliseconds: 200), _loadBatchedDetails);
  }

  /// No longer need the details, remove them from the batched load set if
  /// they're in there.
  void dontNeedDetails(File file) {
    _detailsBatch.remove(file);
  }

  final _detailsCache = HashMap<int, _DetailsCacheEntry>();

  File cachedDetails(int fileId) => _detailsCache[fileId]?.file;

  Future<void> _loadBatchedDetails() async {
    // invalidate expired cached details (note: do we get a notification to our
    // WS if someone renames a file or something? we could remove it from cache
    // early)
    _detailsCache.removeWhere((id, detail) => detail.isExpired);

    final plumber = Plumber();
    List<int> loadList = [];
    for (final file in _detailsBatch) {
      var cached = _detailsCache[file.id];
      if (cached != null) {
        plumber.message<File>(cached.file, cached.file.hashCode);
      } else {
        loadList.add(file.id);
      }
    }

    // Clear the batch so further sets can accumulate while we load.
    _detailsBatch.clear();
    _loadDetailsTimer = null;
    if (loadList.isEmpty) {
      return;
    }

    // Get the file details from the backend, and update the cache if needed.
    final fileDetails = await _fileApi.fileDetails(loadList);

    final fileDetailsList = File.fromDMList(fileDetails);

    for (final file in fileDetailsList) {
      _detailsCache[file.id] = _DetailsCacheEntry(file);
      plumber.message<File>(file, file.hashCode);
    }
  }
}

class _DetailsCacheEntry {
  final DateTime expiration;
  final File file;
  _DetailsCacheEntry(this.file)
      : expiration = DateTime.now().add(const Duration(seconds: 120));

  bool get isExpired => DateTime.now().isAfter(expiration);
}
