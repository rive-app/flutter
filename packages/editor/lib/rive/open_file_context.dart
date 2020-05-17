import 'package:core/coop/connect_result.dart';
import 'package:core/coop/coop_client.dart';
import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/files.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/draw_order_tree_controller.dart';
import 'package:rive_editor/rive/editor_alert.dart';
import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/node_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_editor/rive/stage/tools/vector_pen_tool.dart';
import 'package:rive_editor/rive/vertex_editor.dart';
import 'package:rive_editor/widgets/popup/base_popup.dart';

typedef ActionHandler = bool Function(ShortcutAction action);

enum OpenFileState { loading, error, open }
enum EditorMode { design, animate }

/// Helper for state managed by a single open file. The file may be open (in a
/// tab) but it is not guaranteed to be in memory.
class OpenFileContext with RiveFileDelegate {
  /// Globally unique identifier set for the file, composed of ownerId/fileId.
  final int ownerId;
  final int fileId;

  /// Application context.
  final Rive rive;

  /// The base Rive API.
  final RiveApi api;

  /// The files api.
  final RiveFilesApi filesApi;

  /// File name
  final ValueNotifier<String> _name;
  ValueListenable<String> get name => _name;

  /// The Core representation of the file.
  RiveFile core;

  /// The Stage data for this file.
  Stage _stage;

  OpenFileState _state = OpenFileState.loading;

  final _alerts = ValueNotifier<Iterable<EditorAlert>>([]);

  /// List of alerts
  ValueListenable<Iterable<EditorAlert>> get alerts => _alerts;

  void _alertDismissed(EditorAlert alert) {
    removeAlert(alert);
  }

  /// Add an alert to the alerts list. Returns true if it was added, false if it
  /// was already being shown.
  bool addAlert(EditorAlert value) {
    var alerts = Set.of(_alerts.value);
    if (alerts.add(value)) {
      value.dismissed.addListener(_alertDismissed);
      _alerts.value = alerts;
      return true;
    }
    return false;
  }

  /// Remove an alert from the alerts list.
  bool removeAlert(EditorAlert alert) {
    alert.dismissed.removeListener(_alertDismissed);
    var alerts = Set.of(_alerts.value);
    if (alerts.remove(alert)) {
      _alerts.value = alerts;
      return true;
    }
    return false;
  }

  final _isActive = ValueNotifier<bool>(false);

  /// A listenable value that gets notified when the isActive value changes.
  ValueListenable<bool> get isActiveListenable => _isActive;

  /// Whether this file is the currently active file.
  bool get isActive => _isActive.value;
  set isActive(bool value) {
    if (value == _isActive.value) {
      return;
    }
    _isActive.value = value;
  }

  /// Controller for the hierarchy of this file.
  final ValueNotifier<HierarchyTreeController> treeController =
      ValueNotifier<HierarchyTreeController>(null);

  /// Controller for the draw order of this file.
  final ValueNotifier<DrawOrderTreeController> drawOrderTreeController =
      ValueNotifier<DrawOrderTreeController>(null);

  /// The selection context for this file.
  final SelectionContext<SelectableItem> selection =
      SelectionContext<SelectableItem>();

  /// Whether this file is currently in animate mode.
  final ValueNotifier<EditorMode> mode =
      ValueNotifier<EditorMode>(EditorMode.design);

  final List<ActionHandler> _actionHandlers = [];
  final List<ActionHandler> _releaseActionHandlers = [];

  /// Add an action handler which is will receive any performed action before
  /// the file context attempts to handle it. Return true to let the file
  /// context know that the action has already been handled and should not be
  /// interpretted by any of the remaining handlers. Return false to let the
  /// other handlers attempt to handle it, or ultimately the file context
  /// itself.
  bool addActionHandler(ActionHandler handler) {
    if (_actionHandlers.contains(handler)) {
      return false;
    }

    _actionHandlers.add(handler);
    return true;
  }

  /// Remove an action handler from the chain.
  bool removeActionHandler(ActionHandler handler) =>
      _actionHandlers.remove(handler);

  /// Add an action handler for when the key triggering an action is released.
  bool addReleaseActionHandler(ActionHandler handler) {
    if (_releaseActionHandlers.contains(handler)) {
      return false;
    }

    _releaseActionHandlers.add(handler);
    return true;
  }

  /// Remove a release action handler from the chain.
  bool removeReleaseActionHandler(ActionHandler handler) =>
      _releaseActionHandlers.remove(handler);

  void startDragOperation() => rive.startDragOperation();
  void endDragOperation() => rive.endDragOperation();

  VertexEditor vertexEditor;

  OpenFileContext(
    this.ownerId,
    this.fileId, {
    this.rive,
    String fileName,
    this.api,
    this.filesApi,
  }) : _name = ValueNotifier<String>(fileName);

  Stage get stage => _stage;

  OpenFileState get state => _state;
  final Event stateChanged = Event();

  Future<bool> connect() async {
    if (core != null) {
      // TODO: We're already connected, the user re-clicked on this tab.
      print('TODO: make sure Core connection is still open, maybe ping it?');
    } else {
      // If the spectre cookie doesn't exist, then you're on the web
      // and the browser will handle cookie sending, so don't include
      var filePath = '$ownerId/$fileId';
      String spectre;
      if (api.cookies.containsKey('spectre')) {
        spectre = api.cookies['spectre'];
        final urlEncodedSpectre = Uri.encodeComponent(spectre);
        filePath += '/$urlEncodedSpectre';
      }
      LocalDataPlatform dataPlatform = LocalDataPlatform.make();
      await dataPlatform.initialize();
      core = RiveFile(filePath, api: api, localDataPlatform: dataPlatform);

      var connectionInfo = await filesApi.establishCoop(ownerId, fileId);
      if (connectionInfo == null) {
        return false;
      }
      var result = await core.connect(
        connectionInfo.socketHost,
        filePath,
        spectre,
      );
      if (result == ConnectResult.connected) {
        _state = OpenFileState.open;
      } else {
        _state = OpenFileState.error;
      }
      core.addDelegate(this);
      selection.clear();

      core.advance(0);
      makeStage();
      _stage.tool = AutoTool.instance;
      _resetManagers();
      stateChanged.notify();
    }

    return true;
  }

  @protected
  void makeStage() {
    _stage = Stage(this);
  }

  void dispose() {
    _disposeManagers();
    core?.disconnect();
    _stage?.dispose();
  }

  @override
  void markNeedsAdvance() {
    if (isActive) {
      SchedulerBinding.instance.scheduleFrame();
    }
  }

  bool advance(double elapsed) {
    if (_stage != null && (core.advance(elapsed) || _stage.shouldAdvance)) {
      _stage.advance(elapsed);
      return true;
    }
    return false;
  }

  @override
  void onDirtCleaned() {
    if (treeController.value != null) {
      debounce(treeController.value.flatten);
    }
    if (drawOrderTreeController.value != null) {
      debounce(drawOrderTreeController.value.flatten);
    }
    _stage?.markNeedsAdvance();
  }

  @override
  void onObjectAdded(Core object) {
    if (object is Component) {
      _stage.initComponent(object);
    }
    debounce(treeController.value.flatten);
    debounce(drawOrderTreeController.value.flatten);
  }

  @override
  void onObjectRemoved(Core object) {
    if (object is Component && object.stageItem != null) {
      selection.deselect(object.stageItem);
      _stage.removeItem(object.stageItem);
    }
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
  void onWipe() {
    _stage?.wipe();
    _resetManagers();
  }

  void _disposeManagers() {
    vertexEditor?.dispose();
    treeController.value?.dispose();
    drawOrderTreeController.value?.dispose();
  }

  void _resetManagers() {
    _disposeManagers();

    treeController.value = HierarchyTreeController(this);
    drawOrderTreeController.value = DrawOrderTreeController(
      file: this,
    );
    vertexEditor = VertexEditor(this, stage);
  }

  bool select(SelectableItem item, {bool append}) {
    append ??= rive.selectionMode.value == SelectionMode.multi;
    final success = selection.select(item, append: append);
    return success;
  }

  /// Delete the core items represented by the selected stage items.
  bool deleteSelection() {
    var toRemove = selection.items.toList();
    // Build up the entire set of items to remove.
    Set<Component> deathRow = {};
    for (final item in toRemove) {
      if (item is StageItem) {
        var component = item.component as Component;
        deathRow.add(component);
        // We need to recursively remove children too.
        if (component is ContainerComponent) {
          component.forEachChild((child) => deathRow.add(child));
        }
      }
    }
    if (deathRow.isEmpty) {
      return false;
    }
    deathRow.forEach((item) => item.onDelete());
    deathRow.forEach(core.remove);
    selection.clear();
    core.captureJournalEntry();
    return true;
  }

  bool undo() => core.undo();
  bool redo() => core.redo();

  @override
  void onConnectionStateChanged(CoopConnectionState state) {
    /// We use this to handle changes that can come in during use. Right now we
    /// only handle showing the re-connecting (connecting) state.
    switch (state) {
      case CoopConnectionState.connecting:
        _state = OpenFileState.loading;
        stateChanged.notify();
        break;
      case CoopConnectionState.connected:
        _state = OpenFileState.open;
        stateChanged.notify();
        break;
      default:
        break;
    }
  }

  bool releaseAction(ShortcutAction action) {
    for (final actionHandler in _releaseActionHandlers.reversed) {
      if (actionHandler(action)) {
        return true;
      }
    }
    return false;
  }

  /// Will attempt to perform the given action. If the action is not handled,
  /// [triggerAction] will return false.
  bool triggerAction(ShortcutAction action) {
    // See if any of our handlers care.
    // https://www.youtube.com/watch?v=1o4s1KVJaVA
    for (final actionHandler in _actionHandlers.reversed) {
      if (actionHandler(action)) {
        return true;
      }
    }
    // No one gives a F#$(C<, let's see if we can help this poor friend.
    switch (action) {
      case ShortcutAction.autoTool:
        stage?.tool = AutoTool.instance;
        return true;

      case ShortcutAction.translateTool:
        stage?.tool = TranslateTool.instance;
        return true;

      case ShortcutAction.artboardTool:
        stage?.tool = ArtboardTool.instance;
        return true;

      case ShortcutAction.ellipseTool:
        stage?.tool = EllipseTool.instance;
        return true;

      case ShortcutAction.penTool:
        stage?.tool = VectorPenTool.instance;
        return true;

      case ShortcutAction.rectangleTool:
        stage?.tool = RectangleTool.instance;
        return true;

      case ShortcutAction.nodeTool:
        stage?.tool = NodeTool.instance;
        return true;

      case ShortcutAction.undo:
        undo();
        return true;

      case ShortcutAction.redo:
        redo();
        return true;

      case ShortcutAction.delete:
        // Need to make a new list because as we delete we also remove them
        // from the selection. This avoids modifying the selection set while
        // iterating.
        deleteSelection();
        return true;

      case ShortcutAction.freezeImagesToggle:
        stage?.freezeImages = !stage.freezeImages;
        return true;

      case ShortcutAction.freezeJointsToggle:
        stage?.freezeJoints = !stage.freezeJoints;
        return true;

      case ShortcutAction.resetRulers:
        // TODO: Reset rulers.
        return true;

      case ShortcutAction.toggleRulers:
        stage?.showRulers = !stage.showRulers;
        return true;

      case ShortcutAction.cancel:
        Popup.closeAll();
        return true;

      default:
        return false;
    }
  }

  /// Save the file name
  void changeFileName(String name) {
    _name.value = name;
    filesApi.changeFileName(ownerId, fileId, name);
  }
}
