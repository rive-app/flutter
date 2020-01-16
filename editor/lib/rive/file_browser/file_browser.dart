import 'package:flutter/foundation.dart';
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
  List<FileItem> get selectedFiles =>
      _selectedFolder.files.where((f) => f.isSelected).toList();
  List<FolderItem> get selectedFolders =>
      _selectedFolder.folders.where((f) => f.isSelected).toList();
  int get selectedItemCount => selectedFiles.length + selectedFolders.length;
  FolderItem _selectedFolder;
  int _lastSelectedFileIndex;
  int _lastSelectedFolderIndex;

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
    switch (rive.selectionMode.value) {
      case SelectionMode.single:
        _resetSelection();
        _selectFileItem(value, false);
        _lastSelectedFileIndex = _selectedFolder.files.indexOf(value);
        break;
      case SelectionMode.multi:
        _selectFileItem(value, true);
        _lastSelectedFileIndex = _selectedFolder.files.indexOf(value);
        break;
      case SelectionMode.range:
        if (_lastSelectedFileIndex == null) {
          _selectFileItem(value, false);
          _lastSelectedFileIndex = _selectedFolder.files.indexOf(value);
        } else {
          List<FileItem> _items;
          final _itemIndex = _selectedFolder.files.indexOf(value);

          if (_lastSelectedFileIndex < _itemIndex) {
            _items = _selectedFolder.files
                .getRange(_lastSelectedFileIndex, _itemIndex + 1)
                .toList();
          } else {
            _items = _selectedFolder.files
                .getRange(_itemIndex, _lastSelectedFileIndex + 1)
                .toList();
          }
          _resetSelection();
          for (var item in _items) {
            _selectFileItem(item, true);
          }
          selection.selectMultiple(_items, append: true);
        }
        break;
    }
    notifyListeners();
  }

  void deselectAll() {
    _resetSelection(true);
  }

  void _resetSelection([bool force = false]) {
    selection.clear();
    if (_selectedFolder != null) {
      for (var item in _selectedFolder.files) {
        item.isSelected = false;
      }
      for (var item in _selectedFolder.folders) {
        item.isSelected = false;
      }
    }
  }

  void _selectFileItem(FileItem value, bool append) {
    if (value.isSelected) {
      value.isSelected = false;
      selection.items.remove(value);
      _selectedFolder.files.firstWhere((f) => f.key == value.key).isSelected =
          false;
    } else {
      value.isSelected = true;
      selection.select(value, append: append);
      _selectedFolder.files.firstWhere((f) => f.key == value.key).isSelected =
          true;
    }
  }

  @override
  void openFile(Rive rive, FileItem value) {
    rive.open(value.key.value);
  }

  final _draggingState = ValueNotifier<bool>(false);
  ValueListenable<bool> get draggingState => _draggingState;
  set isDragging(bool val) => _draggingState.value = val;
  bool get isDragging => _draggingState.value;
  void startDrag() {
    isDragging = true;
    for (var item in selectedFiles) {
      item.isDragging = true;
    }
    for (var item in selectedFolders) {
      item.isDragging = true;
    }
     notifyListeners();
  }

  void endDrag() {
    isDragging = false;
    for (var item in selectedFiles) {
      item.isDragging = false;
    }
    for (var item in selectedFolders) {
      item.isDragging = false;
    }
     notifyListeners();
  }
}
