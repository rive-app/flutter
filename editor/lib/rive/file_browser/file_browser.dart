import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/folder.dart';
import 'dart:math' as math;

import 'controller.dart';
import 'file.dart';

class FileBrowser extends FileBrowserController {
  Set<FolderItem> _folders = {};
  FolderItem _selectedFolder;
  SelectionMode _mode = SelectionMode.single;

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
  List<FolderItem> _selectedFolders = [];
  List<FolderItem> get selectedFolders => _selectedFolders;
  List<FileItem> _selectedFiles = [];
  List<FileItem> get selectedFiles => _selectedFiles;

  @override
  void selectFolder(FolderItem value, bool selection) {
    if (selection && selectionMode == SelectionMode.single) {
      for (var file in _selectedFiles) {
        file.select(SelectionState.none);
      }
      for (var folder in _selectedFolders) {
        folder.select(SelectionState.none);
      }
    }
    value.select(selection ? SelectionState.selected : SelectionState.none);
    if (selection) {
      _selectedFolders.add(value);
    } else {
      _selectedFolders.remove(value);
    }
    // notifyListeners();
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
    if (selection && selectionMode == SelectionMode.single) {
      for (var file in _selectedFiles) {
        file.select(SelectionState.none);
      }
      for (var folder in _selectedFolders) {
        folder.select(SelectionState.none);
      }
    }
    value.select(selection ? SelectionState.selected : SelectionState.none);
    if (selection) {
      _selectedFiles.add(value);
    } else {
      _selectedFiles.remove(value);
    }
    // notifyListeners();
  }

  @override
  void openFile(FileItem value) {
    // TODO: implement openFile
  }
}
