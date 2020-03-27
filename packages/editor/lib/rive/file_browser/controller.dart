import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';

import '../rive.dart';
import 'rive_file.dart';
import 'rive_folder.dart';

abstract class FileBrowserController with ChangeNotifier {
  RiveFolder get selectedFolder;
  void openFile(Rive rive, RiveFile value);
  void openFolder(RiveFolder value, bool jumpTo);
  void selectItem(Rive rive, SelectableItem value);
}
