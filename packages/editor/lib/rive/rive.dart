import 'dart:async';

import 'package:core/debounce.dart';
import 'package:core/error_logger/error_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/frame_debounce.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/preferences.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive_clipboard.dart';
import 'package:rive_editor/rive/shortcuts/default_key_binding.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_key_binding.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_keys.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';
import 'package:window_utils/window_utils.dart' as win_utils;

enum HomeSection { files, notifications, community, recents, getStarted }

enum SelectionMode {
  single,
  multi,
  range,
}

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
class Rive {
  /// The system tab for your files and settings.
  static const systemTab = RiveTabItem(icon: PackedIcon.rive, closeable: false);

  final ValueNotifier<SelectionMode> selectionMode =
      ValueNotifier<SelectionMode>(SelectionMode.single);

  final ValueNotifier<bool> isDragOperationActive = ValueNotifier<bool>(false);

  bool get isDragging => isDragOperationActive.value;
  void startDragOperation() => isDragOperationActive.value = true;
  void endDragOperation() => isDragOperationActive.value = false;
  RiveClipboard _clipboard;

  final ScrollController treeScrollController = ScrollController();

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

    _filesApi = FileApi(api);
  }

  /// Available tabs in the editor
  final List<RiveTabItem> fileTabs = [];
  final Event fileTabsChanged = Event();

  final ValueNotifier<OpenFileContext> file =
      ValueNotifier<OpenFileContext>(null);

  /// Currently selected tab
  final ValueNotifier<RiveTabItem> selectedTab =
      ValueNotifier<RiveTabItem>(null);

  final RiveApi api;
  FileApi _filesApi;

  final RiveIconCache iconCache;
  FocusNode _focusNode;

  /// Immediately return focus to the root level.
  void focus() => _focusNode.requestFocus();
  FocusNode get focusNode => _focusNode;

  /// Call to focus on the next frame. This is helpful when there are race
  /// conditions with events propagating in the same event cycle once already
  /// handled.
  void debounceFocus() => debounce(focus);

  /// Initial service client and determine what state the app should be in.
  Future<void> initialize() async {
    bool ready = await api.initialize();
    if (!ready) {
      Plumber().message<AppState>(AppState.catastrophe);
      return;
    }

    // Deal with current user (if any), or send to login page.
    Plumber().getStream<Me>().listen(_onNewMe);
    await UserManager().loadMe();

    // Start the frame callback loop.
    SchedulerBinding.instance.addPersistentFrameCallback(_drawFrame);
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

  void _onNewMe(Me me) {
    if (me.isEmpty) {
      // Signed out.
      // Walk list backwards as we're removing elements.
      for (int i = fileTabs.length - 1; i >= 0; i--) {
        closeTab(fileTabs[i]);
      }

      Plumber().message<AppState>(AppState.login);
      return;
    }

    // Logging in.
    Plumber().message<AppState>(AppState.home);

    // Track the currently logged in user. Any error report will include the
    // currently logged in user for context.
    ErrorLogger.instance.user = ErrorLogUser(
      id: me.ownerId.toString(),
      username: me.username,
    );

    Settings.setString(Preferences.spectreToken, api.cookies['spectre']);

    selectTab(systemTab);
  }

  void closeTab(RiveTabItem value) {
    ErrorLogger.instance.dropCrumb(
      category: 'tabs',
      message: 'close',
      severity: CrumbSeverity.info,
      data: value.file != null
          ? {
              'ownerId': value.file.ownerId.toString(),
              'fileId': value.file.fileId.toString(),
              'name': value.file.name.value,
            }
          : {},
    );

    fileTabs.remove(value);
    fileTabsChanged.notify();
    if (value == selectedTab.value) {
      // TODO: make this nicer, maybe select the closest tab...
      selectTab(fileTabs.isEmpty ? systemTab : fileTabs.last);
    }

    // This is kind of gross, but we do this to ensure the UI has had time to
    // unsubscribe any listeners to notifiers held by the file context.
    var closure = value.file?.dispose;
    if (closure != null) {
      frameDebounce(closure);
    }
  }

  void _changeActiveFile(OpenFileContext context) {
    // Clean up old value if we had one. Important to call this before
    // activating the incoming file to ensure stage and file context cleanup any
    // singletons referencing them or objects owned by them.
    file.value?.isActive = false;

    // Set and init new one...
    file.value = context;
    file.value?.isActive = true;
  }

  void selectTab(RiveTabItem value) {
    if (value == systemTab) {
      _changeActiveFile(null);
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
          : {},
    );
    Plumber().message(value);
    selectedTab.value = value;
  }

  // Actions that the pressed keys are triggering. These get updated as keys are
  // released.
  final Set<ShortcutAction> _pressedActions = {};

  // Actions the system has requested to ignore a release event for. This is
  // cleared when the action is released.
  final Set<ShortcutAction> _canceledActions = {};

  bool _isSystemCmdPressed = false;
  // Returns true if the command on mac or control on win is pressed.
  bool get isSystemCmdPressed => _isSystemCmdPressed;

  /// Prevent a pressed action from triggering its release. We need to track it
  /// as a cancel in order to maintain our sync group for pressed (we can't
  /// simply remove it from pressed as that'd trigger a re-press with repeat).
  bool cancelPress(ShortcutAction action) {
    if (_pressedActions.contains(action)) {
      return _canceledActions.add(action);
    }
    return false;
  }

  final Set<ShortcutKey> _pressedKeys = {};
  void onRawKeyPress(ShortcutKey key, bool isPress, bool isRepeat) {
    // First update our pressed set.
    if (isPress) {
      _pressedKeys.add(key);
    } else {
      _pressedKeys.remove(key);
    }

    if (key == ShortcutKey.systemCmd) {
      _isSystemCmdPressed = isPress;
    }
    selectionMode.value = key == ShortcutKey.shift && isPress
        ? SelectionMode.range
        : _isSystemCmdPressed ? SelectionMode.multi : SelectionMode.single;

    // If something else has focus, don't process actions (usually when a text
    // field is focused somewhere).
    var hasFocusObject = _focusNode != FocusManager.instance.primaryFocus;
    if (hasFocusObject) {
      return;
    }

    ShortcutKeyBinding keyBinding = defaultKeyBinding;
    var actions = <ShortcutAction>{};
    var toTrigger = <ShortcutAction>{};
    if (isPress) {
      // Only trigger actions if a key was pressed.
      actions = keyBinding.lookupAction(_pressedKeys, key);
      // Some actions don't repeat, so remove them from the trigger list if
      // they've already triggered for press. N.B. most platforms give  us a way
      // to determine if this keydown is a repeat, Flutter does this only for
      // Android so we have to do it ourselves here.

      if (isPress) {
        for (final action in actions) {
          if (action.repeats) {
            toTrigger.add(action);
          } else if (!_pressedActions.contains(action)) {
            // Action is not a repeating action, however it wasn't previously
            // pressed so this is the first press down.
            toTrigger.add(action);
          }
        }
      }
    }

    var released = _pressedActions.difference(actions);
    for (final action in released) {
      // If this action had been canceled, skip calling release for it.
      if (_canceledActions.contains(action)) {
        _canceledActions.remove(action);
        continue;
      }
      if (action is StatefulShortcutAction) {
        action.onRelease();
      }
      releaseAction(action);
    }

    _pressedActions.clear();
    _pressedActions.addAll(actions);

    toTrigger.forEach(triggerAction);
  }

  /// This is the old path attempting to handle Flutter key bindings.
  void onKeyEvent(ShortcutKeyBinding keyBinding, RawKeyEvent keyEvent,
      bool hasFocusObject) {}

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
          break;
        case ShortcutAction.copy:
          if (fileContext != null) {
            _clipboard = RiveClipboard.copy(fileContext);
          }
          break;
        case ShortcutAction.paste:
          if (fileContext != null && _clipboard != null) {
            _clipboard.paste(fileContext);
            fileContext.core.captureJournalEntry();
          }
          break;
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
        'ownerId': ownerId.toString(),
        'fileId': fileId.toString(),
        'name': name,
      },
    );

    if (openFileTab == null) {
      var openFile = OpenFileContext(
        ownerId,
        fileId,
        rive: this,
        fileName: name,
        api: api,
        fileApi: _filesApi,
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
          'ownerId': ownerId.toString(),
          'fileId': fileId.toString(),
          'name': name,
        },
      );
    }

    // TODO: this should be moved to a centralized location
    // Mark the first run flag if necessary
    if (Plumber().peek<Me>()?.isFirstRun ?? false) {
      ErrorLogger.instance.dropCrumb(
        category: 'user',
        message: 'marking first run',
        severity: CrumbSeverity.debug,
        data: {
          'ownerId': ownerId.toString(),
          'fileId': fileId.toString(),
          'name': name,
        },
      );
      UserManager().markFirstRun();
    }

    return openFileTab.file;
  }
}
