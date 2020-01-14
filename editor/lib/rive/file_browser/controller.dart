import 'package:flutter/material.dart';

import 'folder.dart';

abstract class FileBrowserController extends ChangeNotifier {
  List<FolderItem> get folders;
  FolderItem get selectedFolder;
  void selectFolder(FolderItem value, bool selection);
  void openFolder(FolderItem value);
}
