import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/files.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_api/owner.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/controller.dart';
import 'package:rive_editor/rive/file_browser/rive_file.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/files_view/screen.dart';

const kTreeItemHeight = 35.0;

class FileBrowser extends FileBrowserController {
  Set<RiveFile> _queuedFileDetails = {};
  Timer _detailsTimer;

  /// Controller for our files in the folder tree.
  final ValueNotifier<FolderTreeController> myTreeController =
      ValueNotifier<FolderTreeController>(null);

  /// Currently selected item.
  final ValueNotifier<SelectableItem> selectedItem =
      ValueNotifier<SelectableItem>(null);
  // Collection for the currently selected items.
  final Set<SelectableItem> _selectedItems = {};

  /// Scroll offset of the files view.
  final ValueNotifier<double> scrollOffset = ValueNotifier<double>(0);

  /// Rectangle marking the start/end of the marquee area.
  final ValueNotifier<Rect> marqueeSelection = ValueNotifier<Rect>(null);

  /// Sort options for the files view.
  final ValueNotifier<List<RiveFileSortOption>> sortOptions =
      ValueNotifier<List<RiveFileSortOption>>([]);

  /// The currently selected sort option.
  final ValueNotifier<RiveFileSortOption> selectedSortOption =
      ValueNotifier<RiveFileSortOption>(null);

  final RiveOwner _owner;
  RiveFolder _current;
  int _lastSelectedIndex;
  _EditorRiveFilesApi _filesApi;
  BoxConstraints _constraints;

  final _draggingState = ValueNotifier<bool>(false);

  FileBrowser(this._owner);

  int get crossAxisCount {
    final w = _constraints.maxWidth;
    final _count = (w / kGridWidth).floor();
    return _count == 0 ? 1 : _count;
  }

  RiveOwner get owener => _owner;
  RiveFolder get currentFolder => _current;
  ValueListenable<bool> get draggingState => _draggingState;
  bool get isDragging =>
      _draggingState.value; //[..._current.folders, ..._current.files];
  set isDragging(bool val) => _draggingState.value = val;

  // TODO: revisit this.
  List<SelectableItem> get selectableItems => [];

  @override
  RiveFolder get selectedFolder => _current;

  Set<SelectableItem> get selectedItems => _selectedItems;

  bool dequeueLoadDetails(RiveFile file) {
    if (_queuedFileDetails.remove(file)) {
      _detailsTimer ??=
          Timer(const Duration(milliseconds: 100), _loadQueuedDetails);
      return true;
    }
    return false;
  }

  void deselectAll() {
    _resetSelection(true);
  }

  void endDrag() {
    isDragging = false;
    for (final item in _selectedItems) {
      if (item is RiveFolder) {
        item.isDragging = false;
      }
      if (item is RiveFile) {
        item.isDragging = false;
      }
    }
    notifyListeners();
  }

  void initialize(Rive rive) {
    _filesApi = _EditorRiveFilesApi(rive.api, this);
    myTreeController.value =
        FolderTreeController([], fileBrowser: this, rive: rive);
  }

  Future<bool> load(Rive rive) async {
    FoldersResult<RiveFolder> result;
    if (_owner is RiveTeam) {
      var dummyFolder = RiveFolder(<String, dynamic>{
        'id': '1',
        'parent': null,
        'name': _owner.name,
        'order': 0,
        'team': _owner
      });
      List<RiveFolder> root = [dummyFolder];
      List<RiveFolder> folders = [dummyFolder];

      result = FoldersResult<RiveFolder>(
          folders: folders, root: root, sortOptions: []);
    } else {
      result = await _filesApi.myFolders();
    }

    sortOptions.value = result.sortOptions;
    if (selectedSortOption.value != null) {
      selectedSortOption.value = result.sortOptions.firstWhere(
          (option) => option.route == selectedSortOption.value.route);
    }
    // Set the first sort option if we haven't got one yet.
    if (result.sortOptions.isNotEmpty && selectedSortOption.value == null) {
      selectedSortOption.value = result.sortOptions[0];
    }

    var data = myTreeController.value.data;
    data.clear();

    // HACK
    if (result.root.length > 0) {
      result.root.first.owner = _owner;
    }

    data.addAll(result.root);

    // await openFolder(result.root.isEmpty ? null : result.root.first, false);
    onFoldersChanged();
    return true;
  }

  void onFoldersChanged() {
    myTreeController.value.flatten();
    myTreeController.notifyListeners();
  }

  @override
  Future<void> openFile(Rive rive, RiveFile value) async {
    var connectionInfo = await _filesApi.establishCoop(value);
    return rive.open(connectionInfo, value.ownerId, value.id, value.name);
  }

  Future<void> createFile() async {
    var newFile = await _filesApi.createFile(folder: _current);
    if (newFile != null) {
      //file.id
      await loadFileList();
      //file.id

      int index =
          _current.files.value.indexWhere((item) => item.id == newFile.id);
      print("File is at index $index");
    }
  }

  Future<bool> loadFileList({RiveFileSortOption sortOption}) async {
    var lastFiles = _current.files.value;

    // Map last files in case they have data we can re-use. This generates a
    // lookup of file-id to old/previously loaded files for this folder. This
    // allows the loading process to re-use the previously loaded file object
    // for this id.
    Map<int, RiveFile> lookup = {};
    if (lastFiles.isNotEmpty) {
      for (final file in lastFiles) {
        lookup[file.id] = file;
      }
    }

    // if the user passes a sort option, update the currently selected sort
    // option.
    if (sortOption != null) {
      selectedSortOption.value = sortOption;
    }

    // TODO: OK gotta do a little thinking here clearly. but i wasnted to talk about this.
    // pretty sure our loadFileList should be giving us an owner.
    // or maybe we stick selected owner into the filebrowser
    // somehwere so we track who we're loading stuff for?
    if (_current.owner == null || _current.owner is RiveUser) {
      var folderFiles = await _filesApi.folderFiles(
          sortOption ?? selectedSortOption.value ?? sortOptions.value[0],
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
    } else {
      // dont have an api for this just yet.
      _current.files.value = [];
    }

    return true;
  }

  @override
  Future<bool> openFolder(RiveFolder value, bool jumpTo) async {
    _current?.isSelected = false;
    _current = value;
    _current?.isSelected = true;

    for (final item in _selectedItems) {
      item.isSelected = false;
    }

    _lastSelectedIndex = null;
    notifyListeners();
    if (value == null) {
      return false;
    }
    myTreeController.value.expand(value);
    if (jumpTo) {
      // TODO: get rive's scrollcontroller? should this live in some kinda selected/userstat context?
      // List<FlatTreeItem<RiveFolder>> _all = myTreeController.value.flat;
      // int _index = _all.indexWhere((f) => f?.data?.key == value.key);
      // double _offset = _index * kTreeItemHeight;
      // rive.treeScrollController.jumpTo(_offset
      //     .clamp(treeScrollController.position.minScrollExtent,
      //         treeScrollController.position.maxScrollExtent)
      //     .toDouble());
    }
    return loadFileList();
  }

  bool queueLoadDetails(RiveFile file) {
    if (_queuedFileDetails.add(file)) {
      _detailsTimer ??=
          Timer(const Duration(milliseconds: 100), _loadQueuedDetails);
      return true;
    }
    return false;
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

  @override
  void selectItem(Rive rive, SelectableItem value) {
    switch (rive.selectionMode.value) {
      case SelectionMode.single:
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
          for (final item in _items) {
            _selectItem(item, true);
          }
        }
        break;
    }

    notifyListeners();
  }

  void sizeChanged(BoxConstraints constraints) => _constraints = constraints;
  void startDrag() {
    isDragging = true;
    for (final item in _selectedItems) {
      if (item is RiveFolder) {
        item.isDragging = true;
      }
      if (item is RiveFile) {
        item.isDragging = true;
      }
    }
    notifyListeners();
  }

  Future<void> _loadQueuedDetails() async {
    _detailsTimer?.cancel();
    _detailsTimer = null;
    var files = _queuedFileDetails.toList(growable: false);
    _queuedFileDetails.clear();
    if (await _filesApi.fillDetails(files)) {}
  }

  void _marqueeSelect(Rive rive) {
    final _itemWidth =
        (_constraints.maxWidth - (kGridSpacing * (crossAxisCount + 1))) /
            crossAxisCount;
    final _itemFolderHeight = (kFolderHeight / kGridWidth) * _itemWidth;
    final _itemFileHeight = (kFileHeight / kGridWidth) * _itemWidth;
    final hasFolders = _current.hasFolders;
    final hasFiles = false; //_current.hasFiles;
    final _marqueeRect = marqueeSelection.value;

    for (final item in selectableItems) {
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
        if (item is RiveFile) {
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

  void _resetSelection([bool force = false]) {
    _selectedItems
      ..forEach((element) {
        element.isSelected = false;
      })
      ..clear();
  }

  void _selectItem(SelectableItem item, bool append) {
    if (!append) {
      _resetSelection();
    }
    if (item.isSelected) {
      item.isSelected = false;
      _selectedItems.remove(item);
    } else {
      item.isSelected = true;
      _selectedItems.add(item);
    }
  }
}

class _EditorRiveFilesApi extends RiveFilesApi<RiveFolder, RiveFile> {
  final FileBrowser _browser;
  _EditorRiveFilesApi(RiveApi api, this._browser) : super(api);

  @override
  RiveFile makeFile(int id) {
    return RiveFile(id, _browser);
  }

  @override
  RiveFolder makeFolder(Map<String, dynamic> data) {
    return RiveFolder(data);
  }
}
