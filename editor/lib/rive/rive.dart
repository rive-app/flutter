import 'dart:async';
import 'dart:math';

import 'package:rive_api/files.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_key_binding.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/coop/connect_result.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_api/user.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';

import 'file_browser/file_browser.dart';
import 'hierarchy_tree_controller.dart';
import 'selection_context.dart';
import 'shortcuts/shortcut_actions.dart';
import 'stage/stage.dart';
import 'stage/stage_item.dart';

enum RiveState { init, login, editor, disconnected, catastrophe }

class _Key {
  final LogicalKeyboardKey logical;
  final PhysicalKeyboardKey physical;

  _Key(this.logical, this.physical);

  @override
  int get hashCode => logical.keyId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _Key && other.logical.keyId == logical.keyId;
  }

  @override
  String toString() {
    return physical.toString();
  }
}

/// Main context for Rive editor.
class Rive with RiveFileDelegate {
  final ValueNotifier<RiveFile> file = ValueNotifier<RiveFile>(null);
  final ValueNotifier<HierarchyTreeController> treeController =
      ValueNotifier<HierarchyTreeController>(null);
  final SelectionContext<SelectableItem> selection =
      SelectionContext<SelectableItem>();
  final ValueNotifier<SelectionMode> selectionMode =
      ValueNotifier<SelectionMode>(SelectionMode.single);
  final ValueNotifier<bool> isAnimateMode = ValueNotifier<bool>(false);

  final FileBrowser fileBrowser = FileBrowser();
  final _user = ValueNotifier<RiveUser>(null);

  Rive({this.iconCache});
  ValueListenable<RiveUser> get user => _user;

  final ValueNotifier<List<RiveTabItem>> tabs =
      ValueNotifier<List<RiveTabItem>>([]);
  final ValueNotifier<RiveTabItem> selectedTab =
      ValueNotifier<RiveTabItem>(null);

  final RiveApi api = RiveApi();
  final RiveIconCache iconCache;
  SharedPreferences _prefs;

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

    // Start the frame callback loop.
    SchedulerBinding.instance.addPersistentFrameCallback(_drawFrame);

    return _state.value;
  }

  int _lastFrameTime = 0;
  void _drawFrame(Duration elapsed) {
    int elapsedMicroseconds = elapsed.inMicroseconds;

    double elapsedSeconds = (elapsedMicroseconds - _lastFrameTime) * 1e-6;
    _lastFrameTime = elapsedMicroseconds;

    if ((file.value?.advance(elapsedSeconds) ?? false) ||
        (_stage?.shouldAdvance ?? false)) {
      _stage.advance(elapsedSeconds);
    }
  }

  @override
  void markNeedsAdvance() {
    SchedulerBinding.instance.scheduleFrame();
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
    // await api.clearCookies();
    var me = await auth.whoami();

    print("whoami ready: ${me != null}");

    if (me != null) {
      _user.value = me;
      tabs.value = [
        RiveTabItem(name: me.name, closeable: false),
      ];
      _state.value = RiveState.editor;
      // Save token in localSettings
      _prefs ??= await SharedPreferences.getInstance();

      // spectre is our session token
      final _spectreToken = api.cookies['spectre'];
      await _prefs.setString('token', _spectreToken);

      openTab(tabs.value.first);

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
    // _stage.markNeedsAdvance();
  }

  @override
  void onDirtCleaned() {
    treeController.value?.flatten();
    _stage?.markNeedsAdvance();
  }

  final Set<_Key> _pressed = {};

  void onKeyEvent(ShortcutKeyBinding keyBinding, RawKeyEvent keyEvent,
      bool hasFocusObject) {
    selectionMode.value = keyEvent.isMetaPressed
        ? SelectionMode.multi
        : keyEvent.isShiftPressed ? SelectionMode.range : SelectionMode.single;

    if (keyEvent is RawKeyDownEvent) {
      _pressed.add(_Key(keyEvent.logicalKey, keyEvent.physicalKey));
    } else if (keyEvent is RawKeyUpEvent) {
      _pressed.remove(_Key(keyEvent.logicalKey, keyEvent.physicalKey));
    }

    // Attempt to synchronize with Flutter's tracked keyset, unfortunately this
    // seems to have an issue where certain keys don't get removed when pressing
    // multiple keys and cmd tabbing.
    _pressed.removeWhere((key) => !keyEvent.isKeyPressed(key.logical));
    // print("PRESSED IS $_pressed ${RawKeyboard.instance.keysPressed}");

    // If something else has focus, don't process actions (usually when a text
    // field is focused somewhere).
    if (hasFocusObject) {
      return;
    }
    var actions = keyBinding.lookupAction(
        _pressed.map((key) => key.physical).toList(growable: false));

    actions?.forEach(triggerAction);
  }

  void triggerAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.translateTool:
        stage?.value?.tool = TranslateTool.instance;
        break;

      case ShortcutAction.artboardTool:
        stage?.value?.tool = ArtboardTool.instance;
        break;

      case ShortcutAction.ellipseTool:
        stage?.value?.tool = EllipseTool.instance;
        break;

      case ShortcutAction.penTool:
        stage?.value?.tool = PenTool.instance;
        break;

      case ShortcutAction.rectangleTool:
        stage?.value?.tool = RectangleTool.instance;
        break;

      case ShortcutAction.undo:
        file.value.undo();
        break;
      case ShortcutAction.redo:
        file.value.redo();
        break;
      case ShortcutAction.delete:
        // Need to make a new list because as we delete we also remove them
        // from the selection. This avoids modifying the selection set while
        // iterating.
        var toRemove = selection.items.toList();
        for (final item in toRemove) {
          if (item is StageItem) {
            file.value.remove(item.component as Core);
          }
        }
        selection.clear();
        file.value.captureJournalEntry();
        break;
      case ShortcutAction.freezeImagesToggle:
        stage?.value?.freezeImages = !stage.value.freezeImages;
        break;
      case ShortcutAction.freezeJointsToggle:
        stage?.value?.freezeJoints = !stage.value.freezeJoints;
        break;
      default:
        break;
    }
  }

  @override
  void onObjectAdded(Core object) {
    _stage.initComponent(object as Component);
  }

  @override
  void onPlayerAdded(ClientSidePlayer player) {
    // only show cursor for other players
    if (player.isSelf) {
      return;
    }
    var stageCursor = StageCursor();
    player.cursorDelegate = stageCursor;
    if (stageCursor.initialize(player)) {
      _stage.addItem(stageCursor);
    }
  }

  @override
  void onPlayerRemoved(ClientSidePlayer player) {
    if (player.cursorDelegate == null) {
      return;
    }
    _stage.removeItem(player.cursorDelegate as StageCursor);
  }

  @override
  void onObjectRemoved(covariant Component object) {
    if (object.stageItem != null) {
      selection.deselect(object.stageItem);
      _stage.removeItem(object.stageItem);
    }
  }

  @override
  void onWipe() {
    print("WIPED! --- 2");
    _stage?.wipe();
    treeController.value =
        HierarchyTreeController(file.value.artboards, rive: this);
  }

  /// Open a Rive file with a specific id. Ids are composed of owner_id:file_id.
  Future<RiveFile> open(CoopConnectionInfo connectionInfo, int ownerId,
      int fileId, String name) async {
    var urlEncodedSpectre = Uri.encodeComponent(api.cookies['spectre']);
    String filePath = '$ownerId/$fileId/$urlEncodedSpectre';

    var opening = RiveFile(filePath, name, api: api);
    var result = await opening.connect(connectionInfo.socketHost, filePath);
    if (result == ConnectResult.connected) {
      print("Connected");
    }
    // Need the delegate before connection completes as some events come in
    // during connection.
    opening.addDelegate(this);
    _changeFile(opening);

    return opening;
  }

  bool select(SelectableItem item, {bool append}) {
    append ??= selectionMode.value == SelectionMode.multi;
    final success = selection.select(item, append: append);
    return success;
  }

  void _changeFile(RiveFile nextFile) {
    // TODO: files should live inside tab items and should disconnect when they
    // are closed.
    file.value?.disconnect();
    file.value = nextFile;
    selection.clear();
    _stage?.dispose();
    nextFile.advance(0);
    _stage = Stage(this, file.value);
    _stage.tool = TranslateTool();
    stage.value = _stage;
    final _tab = RiveTabItem(name: nextFile.name);
    if (!tabs.value.map((t) => t.name).contains(nextFile.name)) {
      tabs.value.add(_tab);
    }
    openTab(_tab);
    // Tree controller is based off of stage items.
    treeController.value =
        HierarchyTreeController(nextFile.artboards, rive: this);
  }

  void forceReconnect() {
    file.value.forceReconnect();
  }
}

enum SelectionMode { single, multi, range }
