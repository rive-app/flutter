import 'package:rive_editor/rive/file_browser/folder.dart';

import 'controller.dart';

class FileBrowser extends FileBrowserController {
  List<FolderItem> _folders = [];
  FolderItem _selectedFolder;

  @override
  List<FolderItem> get folders => _folders;

  @override
  void selectFolder(FolderItem value, bool selection) {
    _folders
        .firstWhere((f) => f.key == value.key, orElse: () => null)
        ?.onSelect(selection);
    notifyListeners();
  }

  @override
  FolderItem get selectedFolder => _selectedFolder;

  @override
  void openFolder(FolderItem value) {
    _selectedFolder = value;
    notifyListeners();
  }
}
