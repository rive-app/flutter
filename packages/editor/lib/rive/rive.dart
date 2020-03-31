import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/models/file.dart';
import 'package:rive_api/folder.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_api/files.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_api/models/team.dart';

import 'package:rive_core/component.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/shapes/shape.dart';

import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';
import 'package:rive_editor/constants.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_key_binding.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/node_tool.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';

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

class _RiveTeamApi extends RiveTeamsApi<RiveTeam> {
  _RiveTeamApi(RiveApi api) : super(api);
}

/// TODO: clean this up, probably want to rework the files api.
class _NonUiRiveFilesApi extends RiveFilesApi<RiveApiFolder, RiveApiFile> {
  _NonUiRiveFilesApi(RiveApi api) : super(api);

  @override
  RiveApiFile makeFile(int id) {
    throw UnsupportedError(
        '_NonUiRiveFilesApi shouldn\'t be used to load file lists.');
  }

  @override
  RiveApiFolder makeFolder(Map<String, dynamic> data) {
    throw UnsupportedError(
        '_NonUiRiveFilesApi shouldn\'t be used to load folder lists.');
  }
}

/// Main context for Rive editor.
class Rive {
  final ValueNotifier<List<RiveTeam>> teams =
      ValueNotifier<List<RiveTeam>>(null);

  final ValueNotifier<SelectionMode> selectionMode =
      ValueNotifier<SelectionMode>(SelectionMode.single);

  final ValueNotifier<bool> isDragOperationActive = ValueNotifier<bool>(false);

  bool get isDragging => isDragOperationActive.value;
  void startDragOperation() => isDragOperationActive.value = true;
  void endDragOperation() => isDragOperationActive.value = false;

  final ValueNotifier<FileBrowser> activeFileBrowser =
      ValueNotifier<FileBrowser>(null);
  final List<FileBrowser> fileBrowsers = [];

  /// Controllers for teams that are associated with our account.
  final ValueNotifier<List<FolderTreeController>> folderTreeControllers =
      ValueNotifier<List<FolderTreeController>>(null);
  final ScrollController treeScrollController = ScrollController();

  final _user = ValueNotifier<RiveUser>(null);

  Rive({this.iconCache, this.focusNode}) : api = RiveApi() {
    _filesApi = _NonUiRiveFilesApi(api);
  }

  ValueListenable<RiveUser> get user => _user;

  /// Available tabs in the editor
  final ValueNotifier<List<RiveTabItem>> tabs =
      ValueNotifier<List<RiveTabItem>>([]);

  List<OpenFileContext> _openFiles = [];
  final Event openFilesChanged = Event();
  List<OpenFileContext> get openFiles => _openFiles;
  final ValueNotifier<OpenFileContext> file =
      ValueNotifier<OpenFileContext>(null);

  /// Currently selected tab
  final ValueNotifier<RiveTabItem> selectedTab =
      ValueNotifier<RiveTabItem>(null);

  final RiveApi api;
  _NonUiRiveFilesApi _filesApi;

  final RiveIconCache iconCache;
  final FocusNode focusNode;
  SharedPreferences _prefs;

  void focus() => focusNode.requestFocus();

  Stage _stage;
  // Stage get stage => _stage;

  final ValueNotifier<Stage> stage = ValueNotifier<Stage>(null);

  final _state = ValueNotifier<RiveState>(RiveState.init);
  ValueListenable<RiveState> get state => _state;

  /// Initial service client and determine what state the app should be in.
  Future<RiveState> initialize() async {
    assert(state.value == RiveState.init);
    bool ready = await api.initialize();
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
      SchedulerBinding.instance.scheduleFrame();
    }
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
        const RiveTabItem(name: 'Changelog', closeable: false),
      ];
      _state.value = RiveState.editor;
      // Save token in localSettings
      _prefs ??= await SharedPreferences.getInstance();

      // spectre is our session token
      final _spectreToken = api.cookies['spectre'];
      await _prefs.setString('token', _spectreToken);

      openTab(tabs.value.first);

      await reloadTeams();

      // TODO: load last opened file list (from localdata)
      return me;
    } else {
      _state.value = RiveState.login;
    }
    return null;
  }

  Future<void> reloadTeams() async {
    // Load the teams to which the user belongs
    fileBrowsers.clear();
    teams.value = await _RiveTeamApi(api).teams;

    final fileBrowser = FileBrowser(user.value);
    fileBrowser.initialize(this);
    await fileBrowser.load(this);
    fileBrowsers.add(fileBrowser);

    teams.value.forEach((RiveTeam team) {
      var _tmp = FileBrowser(team);
      _tmp.initialize(this);
      _tmp.load(this);
      fileBrowsers.add(_tmp);
    });

    activeFileBrowser.value = fileBrowser;
    folderTreeControllers.value = fileBrowsers
        .map((FileBrowser fileBrowser) => fileBrowser.myTreeController.value)
        .toList();

    openActiveFileBrowser();
  }

  void openActiveFileBrowser() {
    activeFileBrowser.value.openFolder(
        activeFileBrowser.value.myTreeController.value.data.isEmpty
            ? null
            : activeFileBrowser.value.myTreeController.value.data.first,
        false);
  }

  void closeTab(RiveTabItem value) {
    tabs.value.remove(value);
    selectedTab.value = tabs.value.last;
  }

  void openTab(RiveTabItem value) {
    if (!value.closeable) {
      // hackity hack hack, this is the files tab.
      fileBrowsers?.forEach((fileBrowser) => fileBrowser.load(this));
    }
    // if (value.name == 'Changelog') {}

    selectedTab.value = value;
  }

  final Set<_Key> _pressed = {};

  void onKeyEvent(ShortcutKeyBinding keyBinding, RawKeyEvent keyEvent,
      bool hasFocusObject) {
    selectionMode.value = keyEvent.isMetaPressed
        ? SelectionMode.multi
        : keyEvent.isShiftPressed ? SelectionMode.range : SelectionMode.single;

    _stage?.updateEditMode(
        keyEvent.isShiftPressed ? EditMode.altMode1 : EditMode.normal);

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

      case ShortcutAction.nodeTool:
        stage?.value?.tool = NodeTool.instance;
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
        file.value?.deleteSelection();
        break;
      case ShortcutAction.freezeImagesToggle:
        stage?.value?.freezeImages = !stage.value.freezeImages;
        break;
      case ShortcutAction.freezeJointsToggle:
        stage?.value?.freezeJoints = !stage.value.freezeJoints;
        break;
      case ShortcutAction.resetRulers:
        print('RESET RULERS HERE');
        break;
      case ShortcutAction.toggleRulers:
        stage?.value?.showRulers = !stage.value.showRulers;
        break;
      case ShortcutAction.toggleEditMode:
        stage?.value?.toggleEditMode();
        break;
      default:
        break;
    }
  }


  void _serializeTabs() {
    // TODO: save open tabs
  }

  /// Open a Rive file with a specific id. Ids are composed of owner_id:file_id.
  Future<OpenFileContext> open(int ownerId, int fileId, String name,
      {bool makeActive = true}) async {
// see if it's already open
    var openFile = _openFiles
        .firstWhere((file) => file.ownerId == ownerId && file.fileId == fileId);

    if (openFile == null) {
      openFile = OpenFileContext(
        ownerId,
        fileId,
        rive: this,
        fileName: name,
        api: api,
        filesApi: _filesApi,
      );
      _openFiles.add(openFile);
      _serializeTabs();
    }

    if (makeActive) {
      file.value = openFile;
      await openFile.connect();
    }

    // var opening = RiveFile(filePath, name, api: api);
    // var result = await opening.connect(
    //   connectionInfo.socketHost,
    //   filePath,
    //   api.cookies['spectre'],
    // );
    // if (result == ConnectResult.connected) {
    //   print("Connected");
    // }
    // // Need the delegate before connection completes as some events come in
    // // during connection.
    // opening.addDelegate(this);
    // _changeFile(opening);

    return openFile;
  }

  // void _changeFile(RiveFile nextFile) {
  //   // TODO: files should live inside tab items and should disconnect when they
  //   // are closed.
  //   file.value?.disconnect();
  //   file.value = nextFile;
  //   selection.clear();
  //   _stage?.dispose();
  //   nextFile.advance(0);
  //   _stage = Stage(this, file.value);
  //   _stage.tool = TranslateTool();
  //   stage.value = _stage;
  //   final _tab = RiveTabItem(name: nextFile.name);
  //   if (!tabs.value.map((t) => t.name).contains(nextFile.name)) {
  //     tabs.value.add(_tab);
  //   }
  //   openTab(_tab);
  //   // Tree controller is based off of stage items.
  //   treeController.value =
  //       HierarchyTreeController(nextFile.artboards, rive: this);
  //   drawOrderTreeController.value = DrawOrderTreeController(
  //       DrawOrderManager(nextFile.artboards).drawableComponentsInOrder,
  //       rive: this);
  // }

  // void forceReconnect() {
  //   file.value.forceReconnect();
  // }
}

enum SelectionMode { single, multi, range }

/// A manager for creating the draw order hierarchy
/// This is a temporary hack until we get the draw
/// order implementation completed. Keeping most of
/// the code in here so it's easy to parse and undo
///
/// TODO: LIST
/// Use the selected artboard to show the items
/// Create a custom icon from the path of the shape
class DrawOrderManager {
  const DrawOrderManager(this.artboards);
  final List<Artboard> artboards;

  List<Component> get drawableComponentsInOrder {
    final components = <Component>[];
    for (final artboard in artboards) {
      for (final component in artboard.children) {
        if (component is Shape) {
          components.add(component);
        }
      }
    }
    return components;
  }
}
