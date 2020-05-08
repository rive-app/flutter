import 'package:rive_api/api.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/src/data_model/data_model.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/src/model/current_directory.dart';
import 'package:rive_api/src/model/folder_contents.dart';

class FolderContentsManager with Subscriptions {
  FolderContentsManager._()
      : _fileApi = FileApi(),
        _folderApi = FolderApi() {
    // Start listening for when a directory changes.
    subscribe<CurrentDirectory>((directory) {
      _getFolderContents(directory);
    });

    subscribe<Me>((me) {
      // Upon init, go get the current users' top folder.
      final myFiles = CurrentDirectory(me, null);
      _getFolderContents(myFiles);
    });
  }

  static FolderContentsManager _instance = FolderContentsManager._();
  factory FolderContentsManager() => _instance;

  final FileApi _fileApi;
  final FolderApi _folderApi;

  void _getFolderContents(CurrentDirectory directory) async {
    Iterable<FileDM> files;
    Iterable<FolderDM> folders;
    var owner = directory.owner;

    if (owner is Team) {
      files = await _fileApi.teamFiles(owner.ownerId, directory.folderId);
      folders = await _folderApi.teamFolders(owner.ownerId);
    } else {
      files = await _fileApi.myFiles(directory.folderId);
      folders = await _folderApi.myFolders();
    }

    print("Got my files & folders:\n$files\n$folders");
    // TODO: don't download them all again?
    // Top folder has ID 1, but its children have their parent ID set to null.
    final parentId = directory.folderId == 1 ? null : directory.folderId;
    folders = folders.where((folder) => folder.parent == parentId);
    var contents = FolderContents(
      File.fromDMList(files.toList(growable: false)),
      Folder.fromDMList(folders.toList(growable: false)),
    );

    Plumber().message<FolderContents>(contents);
  }
}
