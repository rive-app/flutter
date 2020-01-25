import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:shortid/shortid.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:rive_api/files.dart';

import '../../widgets/files_view/screen.dart';
import '../rive.dart';
import 'browser_tree_controller.dart';
import 'controller.dart';
import 'file.dart';
import 'folder.dart';

const kTreeItemHeight = 35.0;

class _EditorRiveFilesApi extends RiveFilesApi<RiveFolder, RiveFile> {
  final FileBrowser _browser;
  _EditorRiveFilesApi(RiveApi api, this._browser) : super(api);

  @override
  RiveFile makeFile(String id) {
    return RiveFile(id, _browser);
  }

  @override
  RiveFolder makeFolder(Map<String, dynamic> data) {
    return RiveFolder(data);
  }
}

class FileBrowser extends FileBrowserController {
  final treeScrollController = ScrollController();
  int get selectedCount => selectedItems.length;
  List<SelectableItem> get selectedItems => [];

  Set<RiveFile> _queuedFileDetails = {};
  Timer _detailsTimer;

  bool queueLoadDetails(RiveFile file) {
    if (_queuedFileDetails.add(file)) {
      _detailsTimer ??= Timer(Duration(milliseconds: 100), _loadQueuedDetails);
      return true;
    }
    return false;
  }

  bool dequeueLoadDetails(RiveFile file) {
    if (_queuedFileDetails.remove(file)) {
      _detailsTimer ??= Timer(Duration(milliseconds: 100), _loadQueuedDetails);
      return true;
    }
    return false;
  }

  Future<void> _loadQueuedDetails() async {
    print("QUEUE IS $_queuedFileDetails");
    _detailsTimer?.cancel();
    _detailsTimer = null;
    var files = _queuedFileDetails.toList(growable: false);
    _queuedFileDetails.clear();
    if (await _filesApi.fillDetails(files)) {}
  }
  /*{
    final _selectedFolders =
        _current.folders.where((f) => f.isSelected).toList();
    final _selectedFiles = _current.files.where((f) => f.isSelected).toList();
    return [..._selectedFolders, ..._selectedFiles];
  }*/

  final treeController = ValueNotifier<FolderTreeController>(null);
  List<FlatTreeItem<RiveFolder>> get teams =>
      treeController.value.flat.skip(1).toList();
  final selection = ValueNotifier<SelectableItem>(null);
  final scrollOffset = ValueNotifier<double>(0);

  final marqueeSelection = ValueNotifier<Rect>(null);
  final sortOptions = ValueNotifier<List<RiveFileSortOption>>([]);

  RiveFolder _current;
  RiveFolder get currentFolder => _current;
  List<SelectableItem> get selectableItems =>
      []; //[..._current.folders, ..._current.files];
  int _lastSelectedIndex;

  _EditorRiveFilesApi _filesApi;

  void initialize(Rive rive) {
    _filesApi = _EditorRiveFilesApi(rive.api, this);
    treeController.value = FolderTreeController([], rive: rive);
  }

  Future<bool> load() async {
    var result = await _filesApi.myFolders();
    sortOptions.value = result.sortOptions;

    var data = treeController.value.data;
    data.clear();
    data.addAll(result.root);
    openFolder(result.root.isEmpty ? null : result.root.first, false);
    onFoldersChanged();
    return true;
  }

  FolderItem _addTeam(Rive rive, int number) {
    final _teamFolder = FolderItem(
      key: ValueKey('team_$number'),
      name: "Team $number",
      files: _genFiles(0),
      folders: _getFolders(math.Random().nextInt(2)),
    );
    return _teamFolder;
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
    final _itemFolderHeight = (kFolderHeight / kGridWidth) * _itemWidth;
    final _itemFileHeight = (kFileHeight / kGridWidth) * _itemWidth;
    final hasFolders = _current.hasFolders;
    final hasFiles = false; //_current.hasFiles;
    final _marqueeRect = marqueeSelection.value;

    for (var item in selectableItems) {
      if (hasFolders) {
        if (item is RiveFolder) {
          int _index = _current.children.indexOf(item);
          int col = _index % crossAxisCount;
          int row = (_index / crossAxisCount).floor();
          final w = _itemWidth;
          final h = _itemFolderHeight;
          final l = kGridSpacing + (col * (kGridSpacing + w));
          final t = kGridHeaderHeight + ((h + kGridSpacing) * row);
          Rect _itemRect = Rect.fromLTWH(l, t, w, h);
          item.isSelected = _marqueeRect?.overlaps(_itemRect) ?? false;
        }
      }
      if (hasFiles) {
        final _offset = hasFolders
            ? (((_current.children.length / crossAxisCount).ceil() *
                        (_itemFolderHeight + kGridSpacing)) +
                    kGridHeaderHeight) +
                kGridHeaderHeight -
                kGridSpacing
            : kGridHeaderHeight;
        if (item is FileItem) {
          int _index = 0; //_current.files.indexOf(item);
          int col = _index % crossAxisCount;
          int row = (_index / crossAxisCount).floor();
          final w = _itemWidth;
          final h = _itemFileHeight;
          final l = kGridSpacing + (col * (kGridSpacing + w));
          final t = _offset + ((h + kGridSpacing) * row);
          Rect _itemRect = Rect.fromLTWH(l, t, w, h);
          item.isSelected = _marqueeRect?.overlaps(_itemRect) ?? false;
        }
      }
    }
  }

  void onFoldersChanged() {
    treeController.value.flatten();
  }

  @override
  RiveFolder get selectedFolder => _current;

  @override
  Future<bool> openFolder(RiveFolder value, bool jumpTo) async {
    _current = value;
    if (selectedCount != 0) {
      for (final item in selectedItems) {
        item.isSelected = false;
      }
    }
    _lastSelectedIndex = null;
    notifyListeners();
    if (value == null) {
      return false;
    }
    treeController.value.expand(value);
    if (jumpTo) {
      List<FlatTreeItem<RiveFolder>> _all = treeController.value.flat;
      int _index = _all.indexWhere((f) => f?.data?.key == value.key);
      double _offset = _index * kTreeItemHeight;
      treeScrollController.jumpTo(_offset);
    }

    var lastFiles = _current.files.value;

    // Map last files in case they have data we can re-use. This generates a
    // lookup of file-id to old/previously loaded files for this folder. This
    // allows the loading process to re-use the previously loaded file object
    // for this id.
    Map<String, RiveFile> lookup = {};
    if (lastFiles.isNotEmpty) {
      for (final file in lastFiles) {
        lookup[file.id] = file;
      }
    }

    var folderFiles = await _filesApi.folderFiles(sortOptions.value[0],
        folder: _current, cacheLocator: (id) {
      var previous = lookup[id];
      // Make sure to allow it to re-load so it gets the data again when it's
      // first scrolled into view. Most of the time this will just get the same
      // data, but in case the user has updated the file in a different view
      // (page/website) or a team-member has done it, we aggressively reload
      // data. We eventually can look into using a socket server to notify when
      // files need to be removed from cache.
      previous?.allowReloadDetails();
      return previous;
    });

    _current.files.value = folderFiles;
    return true;
    // if (result.folders.isNotEmpty) {
    //   //, result.folders.first
    //   var folderFiles = await _filesApi.folderFiles(
    //       result.sortOptions[0], result.folders.first);
    //   // Fill details for the files (normally do this as content scrolls into
    //   // view)
    //   //print("FOLDER FILES $folderFiles");
    //   if (await _filesApi.fillDetails(folderFiles)) {
    //     //print("FILLED FILES $folderFiles");
    //   }
    // }
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
  void openFile(Rive rive, RiveFile value) {
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

List<FolderItem> _getFolders(int level, [int max = 25]) {
  return List.generate(
    max,
    (i) {
      final _key = shortid.generate();
      return FolderItem(
        key: ValueKey(_key),
        name: "Folder $_key",
        files: _genFiles(level),
        folders: level == 0 ? [] : _getFolders(level - 1),
      );
    },
  );
}

List<FileItem> _genFiles(int level) {
  final _key = shortid.generate();
  return List.generate(
    math.Random().nextInt(20),
    (p) => FileItem(
      key: ValueKey(_key),
      name: "File $_key",
      image: "https://www.lunapic.com/editor/premade/transparent.gif",
    ),
  );
}
