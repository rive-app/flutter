import 'dart:async';

import 'package:rive_api/src/plumber.dart';
import 'package:rive_api/src/view_model/directory.dart';
import 'package:rive_api/src/view_model/folder_contents.dart';

mixin Subscriptions {
  List<StreamSubscription> subs;
  void dispose();
}

class FolderContentsManager with Subscriptions {
  FolderContentsManager() {
    print("Let's listen to the current directory!");
    var onDirectoryChanged = Plumber().getStream<CurrentDirectory>();
    var subscription = onDirectoryChanged.listen((directory) {
      // This is set up to listen to directory change events, and return new info.
      print("A new folder has been pushed here! $directory");
      _getFolder(directory.id);
    });
    subs = [subscription];
  }

  @override
  void dispose() {
    subs.forEach((sub) => sub.cancel());
  }

  static void _getFolder(int id) async {
    List<Folder> folders;
    List<File> files;
    if (id == 0) {
      // get top folder:
      folders = [
        // All 'null' parentIds, all contained in the top folder.
        Folder(0, null, 'Deleted Files'),
        Folder(1, null, 'Your Files'),
        Folder(2, null, 'Test Folder'),
      ];

      files = [
        File(0, 'Rive experimnt'),
        File(1, 'Penguin?'),
      ];
    } else {
      folders = [
        // Inner folder. Its parentId is '2', this is a child of 'Test Folder' above.
        Folder(3, 2, 'Inner Folder'),
      ];
      files = [
        File(4, 'Design Project'),
        File(5, 'Penguin?'),
      ];
    }
    print("Adding new folder contents for id:$id");
    Plumber().message(FolderContents(folders, files));
  }
}
