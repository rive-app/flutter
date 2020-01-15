import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'dart:math' as math;

import 'controller.dart';
import 'file.dart';

class FileBrowser extends FileBrowserController {
  final selection = SelectionContext<SelectableItem>();
  Set<FolderItem> _folders = {};
  FolderItem _selectedFolder;

  void init() {
    List.generate(25, (i) {
      _folders.add(
        FolderItem(
            key: ValueKey('00$i'),
            name: "Name $i",
            files: List.generate(math.Random().nextInt(20), (p) {
              return FileItem(
                key: ValueKey("00$p"),
                name: "File $p",
                image: "https://www.lunapic.com/editor/premade/transparent.gif",
              );
            })),
      );
    });
    notifyListeners();
  }

  @override
  List<FolderItem> get folders => _folders.toList();

  @override
  void selectFolder(Rive rive, FolderItem value) {
    if (rive.selectionMode.value == SelectionMode.single) {
      selection.clear();
    }
    bool append = rive.selectionMode.value == SelectionMode.multi;
    selection.select(value, append: append);
    value.isSelected = true;
    notifyListeners();
  }

  @override
  FolderItem get selectedFolder => _selectedFolder;

  @override
  void openFolder(FolderItem value) {
    _selectedFolder = value;
    notifyListeners();
  }

  @override
  void selectFile(Rive rive, FileItem value) {
    if (rive.selectionMode.value == SelectionMode.single) {
      selection.clear();
    }
    bool append = rive.selectionMode.value == SelectionMode.multi;
    selection.select(value, append: append);
    value.isSelected;
    notifyListeners();
  }

  @override
  void openFile(Rive rive, FileItem value) {
    rive.open(value.key.value);
  }
}
