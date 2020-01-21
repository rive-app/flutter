import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/files_view/view.dart';
import 'dart:math' as math;

import 'browser_tree_controller.dart';
import 'controller.dart';
import 'file.dart';

const kTreeItemHeight = 35.0;

class FileBrowser extends FileBrowserController {
  final treeScrollController = ScrollController();
  int get selectedCount => selectedItems.length;
  List<SelectableItem> get selectedItems {
    final _selectedFolders =
        _current.folders.where((f) => f.isSelected).toList();
    final _selectedFiles = _current.files.where((f) => f.isSelected).toList();
    return [..._selectedFolders, ..._selectedFiles];
  }

  FolderItem _myFiles;
  final selection = ValueNotifier<SelectableItem>(null);
  final scrollOffset = ValueNotifier<double>(0);
  final browserController = ValueNotifier<FolderTreeController>(null);
  final marqueeSelection = ValueNotifier<Rect>(null);
  FolderItem _current;
  FolderItem get currentFolder => _current;
  List<SelectableItem> get selectableItems =>
      [..._current.folders, ..._current.files];
  int _lastSelectedIndex;

  void init(Rive rive) {
    _myFiles = FolderItem(
        key: ValueKey('0'), name: "My Files", files: [], //_genFiles(0),
        folders: [] //_getFolders(math.Random().nextInt(6)),
        );
    browserController.value = FolderTreeController([_myFiles], rive: rive);
    reset();
    openFolder(_myFiles, false);
  }

  void rectChanged(Rect value, Rive rive) {
    marqueeSelection.value = value;
    final _listener = () => _marqueeSelect(rive);
    if (value != null) {
      _marqueeSelect(rive);
      scrollOffset.addListener(_listener);
    } else {
      scrollOffset.removeListener(_listener);
    }
  }

  BoxConstraints _constraints;
  int get crossAxisCount {
    final w = _constraints.maxWidth;
    final _count = (w / kGridWidth).floor();
    return _count == 0 ? 1 : _count;
  }

  void sizeChanged(BoxConstraints constraints) => _constraints = constraints;

  void _marqueeSelect(Rive rive) {
    final _itemWidth =
        (_constraints.maxWidth - (kGridSpacing * (crossAxisCount + 1))) /
            crossAxisCount;
    final _offset = scrollOffset.value;
    final hasFolders = _current.hasFolders;
    final hasFiles = _current.hasFiles;
    final _folderGridSize = hasFolders
        ? (_current.folders.length / crossAxisCount) *
            (kFolderAspectRatio * _itemWidth)
        : 0;
    final _folderHeaderOffset = kGridHeaderHeight;
    final _fileHeaderOffset = hasFolders ? kGridHeaderHeight : _folderGridSize;
    final _fileGridSize = hasFiles
        ? kGridHeaderHeight +
            _folderGridSize +
            kGridHeaderHeight +
            (_current.files.length / crossAxisCount) *
                (kFileAspectRatio * _itemWidth)
        : 0;
    final _marqueeRect = marqueeSelection.value;
    for (var item in selectableItems) {
      if (hasFolders) {
        if (item is FolderItem) {
          int _index = _current.folders.indexOf(item);
          int _rowIndex = _index % crossAxisCount;
          int _columnIndex = (_index / crossAxisCount).ceil();
          debugPrint('_rowIndex$_rowIndex, _columnIndex$_columnIndex');
          // final a = Offset(dx, dy);
          // final b = Offset(dx, dy);
          // final _itemRect = Rect.fromPoints(a, b);
        }
      } else {}
    }
    //  List<SelectableItem> _visibleList =
    //     selectableItems.skip(_selectedRow * crossAxisCount).toList();
    print("Marquee Rect: $_marqueeRect");
    // for (var item in )
    // debugPrint("W: $_itemWidth, O: $_offset");
    // final _selectedRow = (_offset / kTreeItemHeight).floor();
    // final _itemsPerRow = crossAxisCount;
    // List<SelectableItem> _visibleList =
    //     selectableItems.skip(_selectedRow * _itemsPerRow).toList();
    // for (var item in _visibleList) {
    //   if (item is FolderItem) {
    //     // final _info = item.rectChanged.value;
    //     // print(
    //     //     "${item.key.value}: ${_info?.visibleFraction}, ${_info?.visibleBounds}");
    //     // if ((_info?.visibleFraction ?? 0) > 0) {
    //     //   final _rect = _info.visibleBounds;
    //     //   item.isSelected = value.overlaps(_rect);
    //     // }
    //     // final _rect = Recrt.fromLTWH(left, top, width, height);
    //   }
    //   if (item is FileItem) {
    //     // final _info = item.rectChanged.value;
    //     // print(
    //     //     "${item.key.value}: ${_info?.visibleFraction}, ${_info?.visibleBounds}");
    //     // if ((_info?.visibleFraction ?? 0) > 0) {
    //     //   final _rect = _info.visibleBounds;
    //     //   item.isSelected = value.overlaps(_rect);
    //     // }
    //   }
    // }
  }

  void onFoldersChanged() {
    browserController.value.flatten();
  }

  void reset() {
    _current = _myFiles;
    selection.value = null;
    onFoldersChanged();
    notifyListeners();
  }

  List<FolderItem> _getFolders(int level) {
    return List.generate(
      25,
      (i) => FolderItem(
        key: ValueKey('folder_$level$i'),
        name: "Name $i ($level)",
        files: _genFiles(level),
        folders: level == 0 ? [] : _getFolders(level - 1),
      ),
    );
  }

  List<FileItem> _genFiles(int level) {
    return List.generate(
      math.Random().nextInt(20),
      (p) => FileItem(
        key: ValueKey("file_$level$p"),
        name: "File $p ($level)",
        image: "https://www.lunapic.com/editor/premade/transparent.gif",
      ),
    );
  }

  @override
  FolderItem get selectedFolder => _current;

  @override
  void openFolder(FolderItem value, bool jumpTo) {
    _current = value;
    if (selectedCount != 0) {
      for (var item in selectedItems) {
        item.isSelected = false;
      }
    }
    browserController.value.expand(value);
    _lastSelectedIndex = null;
    notifyListeners();
    if (jumpTo) {
      final _index = browserController.value.flat
          .indexWhere((f) => f.data.key == value.key);
      final _offset = _index * kTreeItemHeight;
      treeScrollController.jumpTo(_offset);
    }
    // Scrollable.ensureVisible(context);
  }

  @override
  void selectItem(Rive rive, SelectableItem value) {
    switch (rive.selectionMode.value) {
      case SelectionMode.single:
        _resetSelection();
        _selectItem(value, false);
        _lastSelectedIndex = selectableItems.indexOf(value);
        break;
      case SelectionMode.multi:
        _selectItem(value, true);
        _lastSelectedIndex = selectableItems.indexOf(value);
        break;
      case SelectionMode.range:
        if (_lastSelectedIndex == null) {
          _selectItem(value, false);
          _lastSelectedIndex = selectableItems.indexOf(value);
        } else {
          List<SelectableItem> _items;
          final _itemIndex = selectableItems.indexOf(value);
          if (_lastSelectedIndex < _itemIndex) {
            _items = selectableItems
                .getRange(_lastSelectedIndex, _itemIndex + 1)
                .toList();
          } else {
            _items = selectableItems
                .getRange(_itemIndex, _lastSelectedIndex + 1)
                .toList();
          }
          _resetSelection(true);
          for (var item in _items) {
            _selectItem(item, true);
          }
        }
        break;
    }
    selection.value = value;
    notifyListeners();
  }

  void deselectAll() {
    _resetSelection(true);
  }

  void _resetSelection([bool force = false]) {
    for (var item in selectedItems) {
      item.isSelected = false;
    }
    selection.value = null;
  }

  void _selectItem(SelectableItem value, bool append) {
    if (!append) {
      _resetSelection();
    }
    if (value.isSelected) {
      value.isSelected = false;
    } else {
      value.isSelected = true;
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
    for (var item in selectedItems.toList()) {
      if (item is FolderItem) {
        item.isDragging = true;
      }
      if (item is FileItem) {
        item.isDragging = true;
      }
    }
    notifyListeners();
  }

  void endDrag() {
    isDragging = false;
    for (var item in selectedItems) {
      if (item is FolderItem) {
        item.isDragging = false;
      }
      if (item is FileItem) {
        item.isDragging = false;
      }
    }
    notifyListeners();
  }
}
