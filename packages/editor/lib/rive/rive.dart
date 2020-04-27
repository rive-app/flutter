import 'dart:async';
import 'dart:math';

import 'package:core/error_logger/error_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/models/file.dart';
import 'package:rive_api/folder.dart';
import 'package:rive_api/models/owner.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/preferences.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/shortcuts/default_key_binding.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_api/files.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_api/models/team.dart';

import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_key_binding.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';

import 'package:window_utils/window_utils.dart' as win_utils;

enum RiveState { init, login, editor, disconnected, catastrophe }

enum HomeSection { files, notifications, community, recents, getStarted }

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
  RiveApiFile makeFile(int id, {String name, int ownerId}) {
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
  /// The system tab for your files and settings.
  static const systemTab = RiveTabItem(icon: 'rive', closeable: false);

  final ValueNotifier<List<RiveTeam>> teams =
      ValueNotifier<List<RiveTeam>>(null);

  final ValueNotifier<SelectionMode> selectionMode =
      ValueNotifier<SelectionMode>(SelectionMode.single);

  final ValueNotifier<bool> isDragOperationActive = ValueNotifier<bool>(false);

  bool get isDragging => isDragOperationActive.value;
  void startDragOperation() => isDragOperationActive.value = true;
  void endDragOperation() => isDragOperationActive.value = false;

  /// Tracking the home screen state
  final ValueNotifier<HomeSection> sectionListener =
      ValueNotifier(HomeSection.files);

  // HomeSection get section => sectionListener.value;
  // set section(HomeSection value) => sectionListener.value = value;

  final ValueNotifier<FileBrowser> activeFileBrowser =
      ValueNotifier<FileBrowser>(null);

  final List<FileBrowser> fileBrowsers = [];

  /// Controllers for teams that are associated with our account.
  final ValueNotifier<List<FolderTreeController>> folderTreeControllers =
      ValueNotifier<List<FolderTreeController>>(null);
  final ScrollController treeScrollController = ScrollController();

  final _user = ValueNotifier<RiveUser>(null);

  Rive({this.iconCache}) : api = RiveApi() {
    _focusNode = FocusNode(
        canRequestFocus: true,
        skipTraversal: true,
        debugLabel: 'Rive Primary Focus Node',
        onKey: (focusNode, event) {
          onKeyEvent(
            defaultKeyBinding,
            event,
            _focusNode != FocusManager.instance.primaryFocus,
          );
          return false;
        });

    _filesApi = _NonUiRiveFilesApi(api);
    // Add the home screen listener for browser changes
    activeFileBrowser.addListener(() {
      if (activeFileBrowser.value != null &&
          sectionListener.value != HomeSection.files) {
        sectionListener.value = HomeSection.files;
        // This hack is here as we need to notify even
        // if sectionListener's value is already files ...
        sectionListener.notifyListeners();
      }
    });
  }

  ValueListenable<RiveUser> get user => _user;
  // TODO: is this a robust enough check?
  bool get isSignedIn => _user.value != null;

  RiveOwner get currentOwner => activeFileBrowser.value.owner;

  /// Available tabs in the editor
  final List<RiveTabItem> fileTabs = [];
  final Event fileTabsChanged = Event();

  final ValueNotifier<OpenFileContext> file =
      ValueNotifier<OpenFileContext>(null);

  /// Currently selected tab
  final ValueNotifier<RiveTabItem> selectedTab =
      ValueNotifier<RiveTabItem>(null);

  final RiveApi api;
  _NonUiRiveFilesApi _filesApi;

  final RiveIconCache iconCache;
  FocusNode _focusNode;

  void focus() => _focusNode.requestFocus();
  FocusNode get focusNode => _focusNode;

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
  bool _useTime = false;
  void _drawFrame(Duration elapsed) {
    int elapsedMicroseconds = elapsed.inMicroseconds;

    double elapsedSeconds =
        _useTime ? (elapsedMicroseconds - _lastFrameTime) * 1e-6 : 0;
    _lastFrameTime = elapsedMicroseconds;

    if (file.value?.advance(elapsedSeconds) ?? false) {
      // Use elapsed seconds (compute them) only when we are in sustained
      // playback.
      _useTime = true;
      SchedulerBinding.instance.scheduleFrame();
    } else {
      _useTime = false;
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
      _state.value = RiveState.editor;

      // Track the currently logged in user. Any error report will include the
      // currently logged in user for context.
      ErrorLogger.instance.user = ErrorLogUser(
        id: me.ownerId.toString(),
        username: me.username,
      );

      await Settings.setString(
          Preferences.spectreToken, api.cookies['spectre']);

      selectTab(systemTab);
      await reloadTeams();

      // TODO: load last opened file list (from localdata)
      if (fileBrowsers.first.myTreeController.value.data.isNotEmpty) {
        activeFileBrowser.value ??= fileBrowsers.first;
        await fileBrowsers.first.openFolder(
            fileBrowsers.first.myTreeController.value.data.first, false);
      }
      return me;
    } else {
      _state.value = RiveState.login;
    }
    return null;
  }

  Future<void> selectRiveOwner(int riveOwnerId) async {
    var _desiredFileBrowser = fileBrowsers.firstWhere(
      (FileBrowser fileBrowser) => fileBrowser.owner.ownerId == riveOwnerId,
      orElse: () => (activeFileBrowser.value != null)
          ? activeFileBrowser.value
          : fileBrowsers.first,
    );
    if (_desiredFileBrowser.myTreeController.value.data.isNotEmpty) {
      await setActiveFileBrowser(_desiredFileBrowser);
      await _desiredFileBrowser.openFolder(
          _desiredFileBrowser.myTreeController.value.data.first, false);
    }
  }

  Future<void> setActiveFileBrowser(FileBrowser fileBrowser) async {
    activeFileBrowser.value = fileBrowser;
    if (fileBrowser == null) {
      await Settings.clear(Preferences.selectedRiveOwnerId);
    } else {
      await Settings.setInt(
          Preferences.selectedRiveOwnerId, fileBrowser.owner.ownerId);
    }
  }

  // Tell the server that the user has signed out and remove the token from
  // Shared Preferences.
  Future<bool> signout({VoidCallback onSignout}) async {
    var result = await RiveAuth(api).signout();
    if (!result) {
      return false;
    }

    ErrorLogger.instance.dropCrumb(
      category: 'auth',
      message: 'signed out',
      severity: CrumbSeverity.info,
    );

    result = await Settings.clear(Preferences.spectreToken);

    if (!result) {
      return false;
    }
    onSignout?.call();
    _user.value = null;
    _state.value = RiveState.login;
    return true;
  }

  Future<void> reloadTeams() async {
    // Load the teams to which the user belongs

    teams.value = await _RiveTeamApi(api).teams;

    // cache the previously active file browser.
    var oldBrowsers = fileBrowsers.sublist(0);
    fileBrowsers.clear();

    Future<FileBrowser> updateOrCreate(RiveOwner owner) async {
      var _browser = oldBrowsers.firstWhere((fileBrowser) {
        if (fileBrowser.owner.ownerId == owner.ownerId) {
          // TODO: should we have a cleaner way to do this? somekinda copyWith?
          fileBrowser.owner = owner;
          return true;
        }
        return false;
      }, orElse: () {
        var fileBrowser = FileBrowser(owner);
        fileBrowser.initialize(this);
        return fileBrowser;
      });
      await _browser.load();
      return _browser;
    }

    fileBrowsers.add(await updateOrCreate(user.value));

    await updateOrCreate(user.value);
    if (teams.value != null) {
      for (var i = 0; i < teams.value.length; i++) {
        fileBrowsers.add(await updateOrCreate(teams.value[i]));
      }
    }

    folderTreeControllers.value = fileBrowsers
        .map((FileBrowser fileBrowser) => fileBrowser.myTreeController.value)
        .toList();
  }

  void closeTab(RiveTabItem value) {
    ErrorLogger.instance.dropCrumb(
      category: 'tabs',
      message: 'close',
      severity: CrumbSeverity.info,
      data: value.file != null
          ? {
              "ownerId": value.file.ownerId.toString(),
              "fileId": value.file.fileId.toString(),
              "name": value.file.name.value,
            }
          : {
              "icon": value.icon,
            },
    );

    fileTabs.remove(value);
    fileTabsChanged.notify();
    if (value == selectedTab.value) {
      // TODO: make this nicer, maybe select the closest tab...
      selectTab(fileTabs.isEmpty ? systemTab : fileTabs.last);
    }
    value.file?.dispose();
  }

  void _changeActiveFile(OpenFileContext context) {
    file.value?.isActive = false;
    file.value = context;
    file.value?.isActive = true;
  }

  void selectTab(RiveTabItem value) {
    if (value == systemTab) {
      _changeActiveFile(null);
      fileBrowsers?.forEach((fileBrowser) => fileBrowser.load());
    } else if (value.file != null) {
      _changeActiveFile(value.file);
      value.file.connect();
    }

    ErrorLogger.instance.dropCrumb(
      category: 'tabs',
      message: 'select',
      severity: CrumbSeverity.info,
      data: value.file != null
          ? {
              "ownerId": value.file.ownerId.toString(),
              "fileId": value.file.fileId.toString(),
              "name": value.file.name.value,
            }
          : {
              "icon": value.icon,
            },
    );

    selectedTab.value = value;
  }

  final Set<_Key> _pressed = {};
  final Set<ShortcutAction> _pressedActions = {};

  void onKeyEvent(ShortcutKeyBinding keyBinding, RawKeyEvent keyEvent,
      bool hasFocusObject) {
    selectionMode.value = keyEvent.isMetaPressed
        ? SelectionMode.multi
        : keyEvent.isShiftPressed ? SelectionMode.range : SelectionMode.single;

    // TODO: fix this (should be tracked on rive not stage).
    // _stage?.updateEditMode(
    //     keyEvent.isShiftPressed ? EditMode.altMode1 : EditMode.normal);

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
    var actions = (keyBinding.lookupAction(
                _pressed.map((key) => key.physical).toList(growable: false)) ??
            [])
        .toSet();

    var released = _pressedActions.difference(actions);
    for (final action in released) {
      if (action is StatefulShortcutAction) {
        action.onRelease();
      }
      releaseAction(action);
    }

    // Some actions don't repeat, so remove them from the trigger list if
    // they've already triggered for press. N.B. most platforms give  us a way
    // to determine if this keydown is a repeat, Flutter does this only for
    // Android so we have to do it ourselves here.
    Set<ShortcutAction> toTrigger = {};
    for (final action in actions) {
      if (action.repeats) {
        toTrigger.add(action);
      } else if (!_pressedActions.contains(action)) {
        // Action is not a repeating action, however it wasn't previously
        // pressed so this is the first press down.
        toTrigger.add(action);
      }
    }
    _pressedActions.clear();
    _pressedActions.addAll(actions);

    toTrigger.forEach(triggerAction);
  }

  void releaseAction(ShortcutAction action) {
    var fileContext = file.value;
    fileContext?.releaseAction(action);
  }

  void triggerAction(ShortcutAction action) {
    var fileContext = file.value;
    // Let the open file context attempt to process the action if it wants to.
    bool handled = fileContext?.triggerAction(action) ?? false;
    if (handled) {
      return;
    }

    if (action is StatefulShortcutAction) {
      action.onPress();
    } else {
      switch (action) {
        case ShortcutAction.closeTab:
          if (selectedTab.value == systemTab) {
            win_utils.closeWindow();
          } else {
            closeTab(selectedTab.value);
          }
      }
    }
  }

  void _serializeTabs() {
    // TODO: save open tabs
  }

  /// Open a Rive file with a specific id. Ids are composed of owner_id:file_id.
  Future<OpenFileContext> open(int ownerId, int fileId, String name,
      {bool makeActive = true}) async {
    // see if it's already open
    var openFileTab = fileTabs.firstWhere(
        (tab) =>
            tab.file != null &&
            tab.file.ownerId == ownerId &&
            tab.file.fileId == fileId,
        orElse: () => null);

    ErrorLogger.instance.dropCrumb(
      category: 'tabs',
      message: openFileTab == null ? 'open file' : 're-open file',
      severity: CrumbSeverity.info,
      data: {
        "ownerId": ownerId.toString(),
        "fileId": fileId.toString(),
        "name": name,
      },
    );

    if (openFileTab == null) {
      var openFile = OpenFileContext(
        ownerId,
        fileId,
        rive: this,
        fileName: name,
        api: api,
        filesApi: _filesApi,
      );
      openFileTab = RiveTabItem(file: openFile);
      fileTabs.add(openFileTab);
      fileTabsChanged.notify();
      _serializeTabs();
    }

    if (makeActive) {
      selectedTab.value = openFileTab;
      _changeActiveFile(openFileTab.file);
      var connected = await openFileTab.file.connect();

      ErrorLogger.instance.dropCrumb(
        category: 'tabs',
        message: connected ? 'connected to file' : 'failed to connect to file',
        severity: connected ? CrumbSeverity.info : CrumbSeverity.warning,
        data: {
          "ownerId": ownerId.toString(),
          "fileId": fileId.toString(),
          "name": name,
        },
      );
    }
    return openFileTab.file;
  }
}

enum SelectionMode { single, multi, range }
