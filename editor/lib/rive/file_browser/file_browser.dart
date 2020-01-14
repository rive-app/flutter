import 'package:flutter/material.dart';
import 'package:rive_editor/rive/file_browser/folder.dart';

import 'controller.dart';
import 'file.dart';

class FileBrowser extends FileBrowserController {
  Map<Key, FolderItem> _folders = {};
  FolderItem _selectedFolder;
  SelectionMode _mode = SelectionMode.single;

  void init() {
    _folders.addAll({
      ValueKey("001"):
          FolderItem(key: ValueKey("001"), name: "2D Characters", files: [
        FileItem(
          key: ValueKey("001"),
          name: "Dragon",
          image: "https://www.lunapic.com/editor/premade/transparent.gif",
        ),
        FileItem(
          key: ValueKey("002"),
          name: "Flossy",
          image:
              "http://www.pngmart.com/files/10/Dog-Looking-PNG-Transparent-Picture.png",
        ),
        FileItem(
          key: ValueKey("003"),
          name: "The Kid",
          image:
              "http://www.pngmart.com/files/9/Marvel-Thanos-PNG-Free-Download.png",
        ),
        FileItem(
          key: ValueKey("004"),
          name: "Yellow Mech",
          image:
              "https://webstockreview.net/images/clipart-baby-sea-otter-13.png",
        ),
      ]),
      ValueKey("002"):
          FolderItem(key: ValueKey("002"), name: "Sample Characters", files: [
        FileItem(
          key: ValueKey("001"),
          name: "Dragon",
          image: "https://www.lunapic.com/editor/premade/transparent.gif",
        ),
        FileItem(
          key: ValueKey("003"),
          name: "The Kid",
          image:
              "http://www.pngmart.com/files/9/Marvel-Thanos-PNG-Free-Download.png",
        ),
        FileItem(
          key: ValueKey("002"),
          name: "Flossy",
          image:
              "http://www.pngmart.com/files/10/Dog-Looking-PNG-Transparent-Picture.png",
        ),
      ]),
      ValueKey("003"):
          FolderItem(key: ValueKey("003"), name: "Quanta Tests", files: [
        FileItem(
          key: ValueKey("003"),
          name: "The Kid",
          image:
              "http://www.pngmart.com/files/9/Marvel-Thanos-PNG-Free-Download.png",
        ),
        FileItem(
          key: ValueKey("002"),
          name: "Flossy",
          image:
              "http://www.pngmart.com/files/10/Dog-Looking-PNG-Transparent-Picture.png",
        ),
      ]),
      ValueKey("004"):
          FolderItem(key: ValueKey("004"), name: "Partical Systems", files: [
        FileItem(
          key: ValueKey("002"),
          name: "Flossy",
          image:
              "http://www.pngmart.com/files/10/Dog-Looking-PNG-Transparent-Picture.png",
        ),
      ]),
      ValueKey("005"):
          FolderItem(key: ValueKey("005"), name: "Raiders of Odin", files: [
        FileItem(
          key: ValueKey("001"),
          name: "Dragon",
          image: "https://www.lunapic.com/editor/premade/transparent.gif",
        ),
      ]),
    });
    notifyListeners();
  }

  @override
  List<FolderItem> get folders => _folders.values.toList();

  @override
  void selectFolder(FolderItem value, bool selection) {
    _reset();
    _folders[value.key].onSelect(selection);
    notifyListeners();
  }

  void _reset() {
    _folders.forEach((f, i) => i.onSelect(false));
    if (_selectedFolder != null) {
      _selectedFolder.files.forEach((f) => f.onSelect(false));
    }
  }

  @override
  FolderItem get selectedFolder => _selectedFolder;

  @override
  void openFolder(FolderItem value) {
    _selectedFolder = value;
    notifyListeners();
  }

  @override
  void changeSelectionMode(SelectionMode value) {
    _mode = value;
    notifyListeners();
  }

  @override
  SelectionMode get selectionMode => _mode;

  @override
  void selectFile(FileItem value, bool selection) {
    _reset();
    _folders.forEach((f, i) => i.onSelect(false));
    _selectedFolder.files
        .firstWhere((f) => f.key == value.key)
        .onSelect(selection);
    notifyListeners();
  }

  @override
  void openFile(FileItem value) {
    // TODO: implement openFile
  }
}
