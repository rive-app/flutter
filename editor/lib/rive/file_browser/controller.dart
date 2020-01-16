import 'package:flutter/material.dart';
import 'package:rive_editor/rive/rive.dart';

import 'file.dart';
import 'folder.dart';

abstract class FileBrowserController extends ChangeNotifier {
  FolderItem get selectedFolder;
  void selectFolder(Rive rive, FolderItem value);
  void selectFile(Rive rive, FileItem value);
  void openFolder(FolderItem value);
  void openFile(Rive rive, FileItem value);
}
