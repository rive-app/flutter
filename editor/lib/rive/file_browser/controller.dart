import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';

import '../rive.dart';
import 'file.dart';
import 'folder.dart';

abstract class FileBrowserController extends ChangeNotifier {
  RiveFolder get selectedFolder;
  void selectItem(Rive rive, SelectableItem value);
  void openFolder(RiveFolder value, bool jumpTo);
  void openFile(Rive rive, FileItem value);
}
