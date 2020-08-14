import 'package:pedantic/pedantic.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:utilities/utilities.dart';

class FolderContentsManager with Subscriptions {
  factory FolderContentsManager() => _instance;
  static final _instance = FolderContentsManager._();

  FolderContentsManager._()
      : _fileApi = FileApi(),
        _folderApi = FolderApi() {
    _subscribe();
  }

  FolderContentsManager.tester(FileApi fileApi, FolderApi folderApi)
      : _fileApi = fileApi,
        _folderApi = folderApi {
    _subscribe();
  }

  final FileApi _fileApi;
  final FolderApi _folderApi;

  /// Maps the id generated through [szudzik()] using <owner_id, folder_id> that
  /// is a unique couple.
  final _cache = <int, _FolderContentsCache>{};

  void _subscribe() {
    // Start listening for when a directory changes.
    subscribe<CurrentDirectory>((directory) {
      if (directory != null) {
        final cacheId = directory.hashId;
        if (_cache.containsKey(cacheId)) {
          // Send the cached contents right away. Go check if cache needs to be
          // update right after.
          Plumber().message<FolderContents>(
            _cache[cacheId].getAsFolderContents(),
            cacheId,
          );
        } else {
          // Send an empty message right away to display an empty file browser
          // while contents are loading.
          Plumber().message<FolderContents>(
              const FolderContents(isLoading: true), cacheId);
        }
        _getFolderContents(directory);
      }
    });
  }

  Future<void> _loadFileDetails(
      List<File> files, CurrentDirectory directory) async {
    final plumber = Plumber();

    final teamOwnerId =
        directory.owner is Team ? directory.owner.ownerId : null;
    List<int> fileIds = files.map((file) => file.id).toList(growable: false);

    // Get the file details from the backend, and update the cache if needed.
    final fileDetails = await (directory.owner is Team
        ? _fileApi.teamFileDetails(fileIds, teamOwnerId)
        : _fileApi.myFileDetails(fileIds));

    final fileDetailsList = File.fromDMList(fileDetails, teamOwnerId);

    for (final file in fileDetailsList) {
      plumber.message<File>(file, file.hashCode);
    }
  }

  _FolderContentsCache _initCache(
      List<Folder> folders, int ownerId, int currentFolderId) {
    // Make sure thxat all folders' cache is initialized.
    for (final folder in folders) {
      final cacheId = szudzik(ownerId, folder.id);
      _cache[cacheId] ??= _FolderContentsCache();
      // clear folders, the structure will get rebuilt with our folders.
      _cache[cacheId].folders.clear();
    }

    // Add each folder to its parent's cache.
    for (final folder in folders) {
      if (folder.id == 1) {
        // Skip 'Your Files': no parent.
        continue;
      }
      final cacheId = szudzik(ownerId, folder.parent);
      final cache = _cache[cacheId] ??= _FolderContentsCache();
      cache.folders.add(folder);
    }

    // Return _FolderContentsCache for the current directory.
    final currentCacheId = szudzik(ownerId, currentFolderId);
    return _cache[currentCacheId];
  }

  Future<void> _getFolderContents(CurrentDirectory directory) async {
    List<FileDM> files;
    List<FolderDM> folders;
    final owner = directory.owner;
    final ownerId = owner.ownerId;
    final currentFolderId = directory.folder.id;

    if (owner is Team) {
      files = await _fileApi.teamFiles(ownerId, currentFolderId);
      folders = await _folderApi.teamFolders(ownerId);
    } else {
      files = await _fileApi.myFiles(ownerId, currentFolderId);
      folders = await _folderApi.myFolders(ownerId);
    }

    final folderCache =
        _initCache(Folder.fromDMList(folders), ownerId, currentFolderId);

    List<File> fileList = File.fromDMList(files);
    folderCache.setFiles(fileList);

    if (files.isNotEmpty) {
      unawaited(_loadFileDetails(fileList, directory));
    }

    Plumber().message<FolderContents>(
        folderCache.getAsFolderContents(), directory.hashId);
  }

  Future<void> delete() async {
    var selection = Plumber().peek<Selection>();
    var currentDirectory = Plumber().peek<CurrentDirectory>();
    if (currentDirectory.owner is Team) {
      await FileApi().deleteTeamFiles(
        currentDirectory.owner.ownerId,
        selection.files.map((e) => e.id).toList(),
        selection.folders.map((e) => e.id).toList(),
      );
    } else {
      await FileApi().deleteMyFiles(
        selection.files.map((e) => e.id).toList(),
        selection.folders.map((e) => e.id).toList(),
      );
    }

    unawaited(_getFolderContents(currentDirectory));
    unawaited(FileManager().loadFolders(currentDirectory.owner));
  }

  Future<void> rename(Object target, String newName) async {
    var currentDirectory = Plumber().peek<CurrentDirectory>();
    if (target is File) {
      await FileManager().renameFile(target, newName);
    }
    if (target is Folder) {
      if (currentDirectory.owner is User) {
        await FolderApi().renameMyFolder(target.ownerId, target.asDM, newName);
      } else {
        await FolderApi().updateTeamFolder(
          target.ownerId,
          target.asDM,
          newName,
          target.parent,
        );
      }
    }

    unawaited(_getFolderContents(currentDirectory));
    unawaited(FileManager().loadFolders(currentDirectory.owner));
  }
}

class _FolderContentsCache {
  /// Maps parent Folder ID to the Files/Folders it contains.
  /// Files/Folders are also mapped <id, Folder>
  final List<File> _files = [];
  final Set<Folder> folders = {};

  void setFiles(List<File> files) {
    _files.clear();
    _files.addAll(files);
  }

  FolderContents getAsFolderContents({bool loading = false}) => FolderContents(
        files: _files.toList(growable: false),
        folders: folders.toList(growable: false),
        isLoading: loading,
      );
}
