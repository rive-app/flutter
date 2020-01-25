import 'dart:async';
import 'dart:math';

import 'package:core/coop/connect_result.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_api/user.dart';

import 'file_browser/file_browser.dart';
import 'hierarchy_tree_controller.dart';
import 'selection_context.dart';
import 'stage/stage.dart';
import 'stage/stage_item.dart';

enum RiveState { init, login, editor, disconnected, catastrophe }

/// Main context for Rive editor.
class Rive with RiveFileDelegate {
  final file = ValueNotifier<RiveFile>(null);
  final treeController = ValueNotifier<HierarchyTreeController>(null);
  final selection = SelectionContext<SelectableItem>();
  final selectionMode = ValueNotifier<SelectionMode>(SelectionMode.single);
  final fileBrowser = FileBrowser();
  final _user = ValueNotifier<RiveUser>(null);
  ValueListenable<RiveUser> get user => _user;

  final tabs = ValueNotifier<List<RiveTabItem>>([]);
  final selectedTab = ValueNotifier<RiveTabItem>(null);

  final api = RiveApi();

  Stage _stage;
  // Stage get stage => _stage;

  final ValueNotifier<Stage> stage = ValueNotifier<Stage>(null);

  final _state = ValueNotifier<RiveState>(RiveState.init);
  ValueListenable<RiveState> get state => _state;

  /// Initial service client and determine what state the app should be in.
  Future<RiveState> initialize() async {
    assert(state.value == RiveState.init);
    bool ready = await api.initialize();
    fileBrowser.initialize(this);
    if (!ready) {
      return _state.value = RiveState.catastrophe;
    }

    await _updateUserWithRetry();
    return _state.value;
  }

  Timer _reconnectTimer;
  int _reconnectAttempt = 0;

  /// Retry getting the current user with backoff.
  Future<void> _updateUserWithRetry() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      await updateUser();
    } on HttpException {
      _state.value = RiveState.disconnected;
    }
    if (_state.value != RiveState.disconnected) {
      _reconnectAttempt = 0;
      return;
    }

    if (_reconnectAttempt < 1) {
      _reconnectAttempt = 1;
    }
    _reconnectAttempt *= 2;
    var duration = Duration(milliseconds: min(10000, _reconnectAttempt * 500));
    print('Will retry connection in $duration.');
    _reconnectTimer = Timer(
        Duration(milliseconds: _reconnectAttempt * 500), _updateUserWithRetry);
  }

  Future<RiveUser> updateUser() async {
    var auth = RiveAuth(api);
    var me = await auth.whoami();
    if (me != null) {
      _user.value = me;
      tabs.value = [
        RiveTabItem(name: me.name, closeable: false),
        RiveTabItem(name: "Ellipse Testing"),
        RiveTabItem(name: "Spaceman"),
      ];
      _state.value = RiveState.editor;
      // TODO: load last opened file list (from localdata)
      return me;
    } else {
      _state.value = RiveState.login;
    }
    return null;
  }

  void closeTab(RiveTabItem value) {
    tabs.value.remove(value);
    selectedTab.value = tabs.value.last;
  }

  void openTab(RiveTabItem value) {
    if (!value.closeable) {
      // hackity hack hack, this is the files tab.
      fileBrowser.load();
    }
    selectedTab.value = value;
  }

  @override
  void onArtboardsChanged() {
    treeController.value.flatten();
    // TODO: this will get handled by dependency manager.
    _stage.markNeedsAdvance();
  }

  void onKeyEvent(RawKeyEvent keyEvent, bool hasFocusObject) {
    selectionMode.value = keyEvent.isMetaPressed
        ? SelectionMode.multi
        : keyEvent.isShiftPressed ? SelectionMode.range : SelectionMode.single;
    // print(
    //     "IS ${keyEvent.physicalKey == PhysicalKeyboardKey.keyZ} ${keyEvent is RawKeyDownEvent} ${keyEvent.isMetaPressed} && ${keyEvent.isShiftPressed} ${keyEvent.physicalKey} ${keyEvent.isMetaPressed && keyEvent.isShiftPressed && keyEvent is RawKeyDownEvent && keyEvent.physicalKey == physicalKeyboardKey.keyZ}");
    if (keyEvent.isMetaPressed &&
        keyEvent.isShiftPressed &&
        keyEvent is RawKeyDownEvent &&
        keyEvent.physicalKey == PhysicalKeyboardKey.keyZ) {
      file.value.redo();
    } else if (keyEvent.isMetaPressed &&
        keyEvent is RawKeyDownEvent &&
        keyEvent.physicalKey == PhysicalKeyboardKey.keyZ) {
      file.value.undo();
    } else if (keyEvent is RawKeyDownEvent &&
        keyEvent.physicalKey == PhysicalKeyboardKey.delete) {
      for (final item in selection.items) {
        if (item is StageItem) {
          file.value.remove(item.component as Core);
        }
      }
      selection.clear();
      file.value.captureJournalEntry();
    }
  }

  @override
  void onObjectAdded(Core object) {
    _stage.initComponent(object as Component);
  }

  @override
  void onObjectRemoved(covariant Component object) {
    if (object.stageItem != null) {
      _stage.removeItem(object.stageItem);
    }
  }

  /// Open a Rive file with a specific id. Ids are composed of owner_id:file_id.
  Future<RiveFile> open(String id) async {
    var opening = RiveFile(id);
    var result = await opening.connect('ws://localhost:8000/$id');
    if (result == ConnectResult.connected) {
      print("Connected");
    }
    opening.addDelegate(this);
    _changeFile(opening);
    return opening;
  }

  bool select(SelectableItem item, {bool append}) {
    if (append == null) {
      append = selectionMode.value == SelectionMode.multi;
    }
    return selection.select(item, append: append);
  }

  void _changeFile(RiveFile nextFile) {
    file.value = nextFile;
    selection.clear();
    _stage?.dispose();
    _stage = Stage(this, file.value);
    _stage.tool = TranslateTool();
    stage.value = _stage;
    final _tab = RiveTabItem(name: nextFile.fileId);
    if (!tabs.value.map((t) => t.name).contains(nextFile.fileId)) {
      tabs.value.add(_tab);
    }
    openTab(_tab);
    // Tree controller is based off of stage items.
    treeController.value =
        HierarchyTreeController(nextFile.artboards, rive: this);
  }
}

enum SelectionMode { single, multi, range }
