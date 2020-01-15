import 'package:flutter/material.dart';
import 'package:rive_editor/rive/rive.dart';

import 'file.dart';
import 'folder.dart';

abstract class FileBrowserController extends ChangeNotifier {
  List<FolderItem> get folders;
  FolderItem get selectedFolder;
  SelectionMode get selectionMode;
  void selectFolder(FolderItem value, bool selection);
  void selectFile(FileItem value, bool selection);
  void openFolder(FolderItem value);
  void openFile(Rive rive, FileItem value);
  void changeSelectionMode(SelectionMode value);
}

enum SelectionMode {
  single,
  multi,
}
