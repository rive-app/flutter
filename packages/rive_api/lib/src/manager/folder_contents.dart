import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

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

  void _subscribe() {
    // Start listening for when a directory changes.
    subscribe<CurrentDirectory>((directory) {
      // Send an empty message right away to display an empty file browser
      // while contents are loading.
      // TODO: caching
      Plumber().message<FolderContents>(FolderContents.empty());
      if (directory != null) {
        _getFolderContents(directory);
      }
    });

    subscribe<Me>((me) {
      // Upon init, go get the current users' top folder.
      final myFiles = CurrentDirectory(me, 1);
      Plumber().message<CurrentDirectory>(myFiles);
    });
  }

  void _loadFileDetails(List<int> fileIds, int teamOwnerId) {
    _fileApi.getFileDetails(fileIds, ownerId: teamOwnerId).then((fileDetails) {
      final plumber = Plumber();
      final fileDetailsList = File.fromDMList(fileDetails, teamOwnerId);
      for (final file in fileDetailsList) {
        plumber.message<File>(file, file.hashCode);
      }
    });
  }

  List<Folder> _filterByParent(
      List<FolderDM> folders, CurrentDirectory directory) {
    final parentId = directory.folderId;

    return folders.fold(
      <Folder>[],
      (list, folderDM) {
        // Add to results if:
        // - parent id is the same
        // - downloading top folder: we want to show 'Deleted Files'.
        if (folderDM.parent == parentId ||
            (parentId == 1 && folderDM.id == 0)) {
          list.add(Folder.fromDM(folderDM));
        }
        return list;
      },
    ).toList(growable: false);
  }

  void _getFolderContents(CurrentDirectory directory) async {
    List<FileDM> files;
    List<FolderDM> folders;
    var owner = directory.owner;

    if (owner is Team) {
      files = await _fileApi.teamFiles(owner.ownerId, directory.folderId);
      folders = await _folderApi.teamFolders(owner.ownerId);
    } else {
      files = await _fileApi.myFiles(owner.ownerId, directory.folderId);
      folders = await _folderApi.myFolders();
    }

    print("Got my files & folders:\n$files\n$folders");
    if (files.isNotEmpty) {
      // Load and prepare pipes for files.
      var fileIds = files.map((e) => e.id).toList(growable: false);
      final directoryOwner =
          directory.owner is Team ? directory.owner.ownerId : null;
      _loadFileDetails(fileIds, directoryOwner);
    }

    final filteredFolders = _filterByParent(folders, directory);

    var contents =
        FolderContents(File.fromDMList(files, owner.ownerId), filteredFolders);

    Plumber().message<FolderContents>(contents);
  }
}
