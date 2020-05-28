import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:utilities/utilities.dart';

class FolderContentsManager with Subscriptions {
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

  static FolderContentsManager _instance = FolderContentsManager._();
  factory FolderContentsManager() => _instance;

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
              FolderContents(isLoading: true), cacheId);
        }
        _getFolderContents(directory);
      }
    });

    subscribe<Me>((me) {
      // Upon init, go get the current users' top folder.
      final myFiles = CurrentDirectory(me, 1);
      Plumber().message<CurrentDirectory>(myFiles);
    });
  }

  void _loadFileDetails(List<File> files, CurrentDirectory directory) async {
    final plumber = Plumber();

    final cache = (_cache[directory.hashId] ??= _FolderContentsCache());

    for (final file in files) {
      final cachedFile = cache.files.lookup(file);
      if (cachedFile != null) {
        plumber.message<File>(cachedFile, cachedFile.hashCode);
      }
    }
    final fileIdSet = files.toSet();
    cache.files.removeWhere((file) => !fileIdSet.contains(file.id));

    final teamOwnerId =
        directory.owner is Team ? directory.owner.ownerId : null;
    List<int> fileIds = files.map((file) => file.id).toList(growable: false);

    // Get the file details from the backend, and update the cache if needed.
    final fileDetails = await (directory.owner is Team
        ? _fileApi.teamFileDetails(fileIds, teamOwnerId)
        : _fileApi.myFileDetails(fileIds));

    final fileDetailsList = File.fromDMList(fileDetails, teamOwnerId);
    final currentDirectoryId = plumber.peek<CurrentDirectory>().folderId;
    // Early out if we swapped folders in quick succession.
    if (currentDirectoryId != directory.folderId) {
      return;
    }

    for (final file in fileDetailsList) {
      cache.files.add(file);
      plumber.message<File>(file, file.hashCode);
    }
    Plumber().message<FolderContents>(
        FolderContents(
            files: cache.files.toList(), folders: cache.folders.toList()),
        directory.hashId);
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
      final cache = (_cache[cacheId] ??= _FolderContentsCache());
      cache.folders.add(folder);
    }

    // Return _FolderContentsCache for the current directory.
    final currentCacheId = szudzik(ownerId, currentFolderId);
    return _cache[currentCacheId];
  }

  void _getFolderContents(CurrentDirectory directory) async {
    List<FileDM> files;
    List<FolderDM> folders;
    final owner = directory.owner;
    final ownerId = owner.ownerId;
    final currentFolderId = directory.folderId;

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
    List<Folder> folderList = folderCache.folders.toList(growable: false);

    if (files.isNotEmpty) {
      _loadFileDetails(fileList, directory);
    }

    Plumber().message<FolderContents>(
        FolderContents(files: fileList, folders: folderList), directory.hashId);
  }

  void delete() async {
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

    _getFolderContents(currentDirectory);
    FileManager().loadFolders(currentDirectory.owner);
  }

  void rename(target, String newName) async {
    var currentDirectory = Plumber().peek<CurrentDirectory>();
    if (target is File) {
      if (currentDirectory.owner is User) {
        await FileApi()
            .renameMyFile(currentDirectory.owner.ownerId, target.id, newName);
      } else {
        await FileApi()
            .renameTeamFile(currentDirectory.owner.ownerId, target.id, newName);
      }
    }
    if (target is Folder) {
      if (currentDirectory.owner is User) {
        await FolderApi().renameMyFolder(
            currentDirectory.owner.ownerId, target.asDM, newName);
      } else {
        await FolderApi().updateTeamFolder(
          currentDirectory.owner.ownerId,
          target.asDM,
          newName,
          target.parent,
        );
      }
    }

    _getFolderContents(currentDirectory);
    FileManager().loadFolders(currentDirectory.owner);
  }
}

class _FolderContentsCache {
  /// Maps parent Folder ID to the Files/Folders it contains.
  /// Files/Folders are also mapped <id, Folder>
  final files = <File>{};
  final folders = <Folder>{};

  List<Folder> getFoldersByParent(int parentId) => folders
      .where((folder) =>
          // Add to results if:
          // - parent id is the same
          // - downloading top folder: we want to show 'Deleted Files'.
          folder.parent == parentId || (parentId == 1 && folder.id == 0))
      .toList(growable: false);

  FolderContents getAsFolderContents({bool loading = false}) => FolderContents(
        files: files.toList(growable: false),
        folders: folders.toList(growable: false),
        isLoading: loading,
      );
}
