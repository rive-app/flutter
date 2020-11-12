import 'dart:async';

import 'package:core/coop/coop_client.dart';
import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/alerts/action_alert.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/editor_alert.dart';
import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/rive/managers/animation/animations_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/rive/managers/revision_manager.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/artboard_tool.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/bone_tool.dart';
import 'package:rive_editor/rive/stage/tools/ellipse_tool.dart';
import 'package:rive_editor/rive/stage/tools/node_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_editor/rive/stage/tools/vector_pen_tool.dart';
import 'package:rive_editor/rive/vertex_editor.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/popup/base_popup.dart';

typedef ActionHandler = bool Function(ShortcutAction action);

enum OpenFileState { loading, error, open, sleeping, timeout }
enum EditorMode { design, animate }

class SleepData {
  final Iterable<Id> selection;
  final Iterable<Id> treeExpansion;

  SleepData({this.selection, this.treeExpansion});
}

/// Helper for state managed by a single open file. The file may be open (in a
/// tab) but it is not guaranteed to be in memory.
class OpenFileContext with RiveFileDelegate {
  /// Globally unique identifier set for the file, composed of ownerId/fileId.
  bool fileInitialized = false;
  final File file;
  int get ownerId => file.fileOwnerId;
  int get fileId => file.id;

  /// Application context.
  final Rive rive;

  /// The base Rive API.
  final RiveApi api;

  /// The files api.
  final FileApi fileApi;

  /// File name
  final ValueNotifier<String> _name;
  ValueListenable<String> get name => _name;

  String get tabName => _name.value;
  set tabName(String value) => _name.value = value;

  final _activeArtboard = ValueNotifier<Artboard>(null);
  Listenable get activeArtboardChanged => _activeArtboard;

  // this complains about types as a setter.
  // ignore: use_setters_to_change_properties
  void updateName(String name) => _name.value = name;

  /// The Core representation of the file.
  RiveFile core;

  /// The Stage data for this file.
  final ValueNotifier<Stage> _stage = ValueNotifier<Stage>(null);
  ValueListenable<Stage> get stageListenable => _stage;
  Stage get stage => _stage.value;

  OpenFileState _state = OpenFileState.loading;
  DateTime _nextConnectionAttempt;
  String _stateInfo;
  Timer _sleepTimer;
  SleepData _sleepData;

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
    final alerts = Set.of(_alerts.value);
    if (alerts.remove(alert)) {
      _alerts.value = alerts;
      return true;
    }
    if (alert == _labeledAlert) {
      _labeledAlert = null;
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
    delaySleep();
  }

  /// Controller for the hierarchy of this file.
  final ValueNotifier<HierarchyTreeController> treeController =
      ValueNotifier<HierarchyTreeController>(null);

  /// The selection context for this file.
  final SelectionContext<SelectableItem> selection =
      SelectionContext<SelectableItem>();

  final ValueNotifier<EditorMode> _mode =
      ValueNotifier<EditorMode>(EditorMode.design);

  /// Whether this file is currently in animate mode.
  ValueListenable<EditorMode> get mode => _mode;

  void changeMode(EditorMode mode) {
    if (_mode.value == mode) {
      return;
    }
    _mode.value = mode;
    _syncActiveArtboard();
    // If animate mode is selected, automatically
    // select the auto tool

    if (mode == EditorMode.animate) {
      var tool = stage.tool;
      // Add other tools here when we have them like rotate and scale:
      // https://github.com/rive-app/rive/issues/820
      if (tool != TranslateTool.instance) {
        stage.tool = AutoTool.instance;
      }
    }
  }

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

  VertexEditor _vertexEditor;
  VertexEditor get vertexEditor => _vertexEditor;

  final ValueNotifier<AnimationsManager> _animationsManager =
      ValueNotifier<AnimationsManager>(null);
  ValueListenable<AnimationsManager> get animationsManager =>
      _animationsManager;

  final ValueNotifier<KeyFrameManager> _keyFrameManager =
      ValueNotifier<KeyFrameManager>(null);
  ValueListenable<KeyFrameManager> get keyFrameManager => _keyFrameManager;

  final ValueNotifier<EditingAnimationManager> _editingAnimationManager =
      ValueNotifier<EditingAnimationManager>(null);
  ValueListenable<EditingAnimationManager> get editingAnimationManager =>
      _editingAnimationManager;

  OpenFileContext(
    this.file, {
    this.rive,
    this.api,
    this.fileApi,
  }) : _name = ValueNotifier<String>(file.name) {
    ShortcutAction.freezeToggle.addListener(_changeFreeze);
    _changeFreeze();
  }

  SimpleAlert _freezeAlert;
  void _changeFreeze() {
    if (ShortcutAction.freezeToggle.value) {
      if (_freezeAlert == null) {
        _freezeAlert = SimpleAlert('Freeze active', autoDismiss: false);
        addAlert(_freezeAlert);
      }
    } else if (_freezeAlert != null) {
      removeAlert(_freezeAlert);
      _freezeAlert = null;
    }
  }

  DateTime get nextConnectionAttempt => _nextConnectionAttempt;
  OpenFileState get state => _state;
  String get stateInfo => _stateInfo;

  final Event stateChanged = Event();

  Future<bool> connect() async {
    if (core == null) {
      // If the spectre cookie doesn't exist, then you're on the web
      // and the browser will handle cookie sending, so don't include

      var filePath = '$fileId';
      String spectre;
      if (api.cookies.containsKey('spectre')) {
        spectre = api.cookies['spectre'];
      }
      LocalDataPlatform dataPlatform = LocalDataPlatform.make();
      await dataPlatform.initialize();
      core = RiveFile(filePath, api: api, localDataPlatform: dataPlatform);
      core.addConnectionDelegate(this);

      var connectionInfo = await fileApi.establishCoop();
      if (connectionInfo == null) {
        return false;
      }
      await core.connect(
        connectionInfo.socketHost,
        filePath,
        spectre,
      );
    }

    return true;
  }

  @protected
  void completeInitialConnection(OpenFileState state, [String info]) {
    _stateInfo = info;
    _state = state;
    if (state == OpenFileState.error) {
      stateChanged.notify();
      return;
    }
    if (core.patched) {
      _showPatchedAlert();
    }
    core.addDelegate(this);
    selection.clear();

    core.advance(0);
    makeStage();
    // We need to first activate the translate tool so that its activate()
    // function is called and the stage set in the tool. If we don't do this and
    // use the autotool first, translating won't have access to the stage, which
    // will break snapping selection.
    stage.tool = TranslateTool.instance;
    stage.tool = AutoTool.instance;
    _resetManagers();
    stateChanged.notify();
    delaySleep();
  }

  @protected
  void makeStage() {
    _stage.value = Stage(this);
  }

  void dispose() {
    _labeledAlert?.dismissed?.removeListener(_alertDismissed);
    _disposeManagers();
    _connectedCore?.disconnect();
    _stage.value?.dispose();
    _previewListener?.cancel();
    _previewListener = null;
    _selectPreviewListener?.cancel();
    _selectPreviewListener = null;
  }

  RiveFile get _connectedCore => _activeRevision ?? core;

  @override
  void markNeedsAdvance() {
    if (isActive) {
      SchedulerBinding.instance.scheduleFrame();
    }
  }

  bool advance(double elapsed) {
    var stageValue = _stage.value;
    if (stageValue != null &&
        (core.advance(elapsed) || stageValue.shouldAdvance)) {
      stageValue.advance(elapsed);
      return true;
    }
    return false;
  }

  void reconnect({bool now = true}) {
    _connectedCore.reconnect(now: now);
  }

  void delaySleep() {
    switch (_state) {
      case OpenFileState.sleeping:
        // Notify the UI that the state had changed when we slept.
        stateChanged.notify();

        _sleepTimer?.cancel();
        reconnect(now: false);
        break;
      case OpenFileState.open:
        _sleepTimer?.cancel();
        _sleepTimer =
            Timer(Duration(seconds: _isActive.value ? 30 : 5), _sleep);
        break;
      default:
        // Don't do anything if we're not connected or already asleep.
        return;
    }
  }

  void _sleep() {
    // tell manager to sleep and serialize any of their selection...
    // _editingAnimationManager.onSleep();
    // .. later do:
    // _editingAnimationManager.onAwake();

    _sleepData = SleepData(
      selection: selection.items
          .whereType<StageItem>()
          .map((item) => (item.component as Component).id)
          .toList(),
      treeExpansion: treeController.value == null
          ? []
          : treeController.value.expanded
              .map((component) => component.id)
              .toList(),
    );
    var notify = OpenFileState.open != _state;
    _state = OpenFileState.sleeping;
    if (notify) {
      // N.B.
      // only calling stateChanged.notify() when changing state from an
      // open file. anything else we may as well notify.
      // Open files will look 'original' so users can use a rive tab for
      // file reference. Any subsequent call to delaySleep() will notify the ui
      stateChanged.notify();
    }

    _connectedCore?.disconnect();
  }

  @override
  void onDirtCleaned() {
    if (treeController.value != null) {
      debounce(treeController.value.flatten);
    }
    stage?.markNeedsAdvance();
  }

  @override
  void onObjectAdded(Core object) {
    if (object is Component) {
      stage.initComponent(object);
    }
    debounce(treeController.value.flatten);
  }

  @override
  void onObjectRemoved(Core object) {
    if (object is Component && object.stageItem != null) {
      stage.removeItem(object.stageItem);
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
      stage.addItem(stageCursor);
    }
  }

  @override
  void onPlayerRemoved(ClientSidePlayer player) {
    if (player.cursorDelegate == null) {
      return;
    }
    stage.removeItem(player.cursorDelegate as StageCursor);
  }

  @override
  void onWipe() {
    // Make sure to remove any stage items so they don't stick around after
    // wiping the stage.
    for (final player in core.players.cast<ClientSidePlayer>()) {
      if (player.cursorDelegate is StageCursor) {
        stage?.removeItem(player.cursorDelegate as StageCursor);
        // Set it to null so it can be re-added.
        player.cursorDelegate = null;
      }
    }
    // N.B. this will only callback during a reconnect wipe, not initial wipe as
    // our delegate isn't registered yet. So we can use this opportunity to wipe
    // the existing stage and set ourselves up for the next set of data.
    stage?.wipe();
    _restoringAlert?.dismiss();
    _restoringAlert = null;
  }

  void _disposeManagers() {
    vertexEditor?.dispose();

    _selectedAnimationSubscription?.cancel();
    _selectedAnimationSubscription = null;
    _syncEditingAnimation(null);
    _animationsManager.value?.dispose();
    _animationsManager.value = null;

    if (treeController.value != null) {
      cancelDebounce(treeController.value.flatten);
      var oldController = treeController.value;
      treeController.value = null;
      debounce(oldController.dispose, duration: const Duration(seconds: 1));
      // oldController.dispose();
    }

    _backboard?.activeArtboardChanged?.removeListener(_syncActiveArtboard);
    _backboard = null;
  }

  List<InspectorBuilder> inspectorBuilders() {
    return vertexEditor.inspectorBuilders();
  }

  void _resetManagers() {
    _disposeManagers();
    treeController.value = HierarchyTreeController(this);
    if (_sleepData != null) {
      var controller = treeController.value;
      for (final id in _sleepData.treeExpansion) {
        var component = core.resolve<Component>(id);
        if (component == null) {
          continue;
        }
        controller.expand(component, callFlatten: false);
      }
      controller.flatten();
    }
    _vertexEditor = VertexEditor(this, stage);

    // This can happen during a _wipe call during initialization, this is
    // considered ok as when the connection succeeds this method is called
    // again.
    if (core.backboard == null) {
      return;
    }

    assert(_backboard == null,
        'Previously held reference to _backboard should\'ve cleared');
    assert(core.backboard != null,
        'Core must have a backboard by the time we\'re connected');

    (_backboard = core.backboard)
        .activeArtboardChanged
        .addListener(_syncActiveArtboard);
    _syncActiveArtboard();
  }

  SelectionMode get selectionMode => rive.selectionMode.value;

  bool select(
    SelectableItem item, {
    bool append,
    bool skipHandlers = false,
  }) {
    append ??= rive.selectionMode.value == SelectionMode.multi;

    /// When appending, toggle selection in the set, so already selected items
    /// should be removed from the set. TODO: consider moving to
    /// [SelectionContext]? https://github.com/rive-app/rive/issues/823
    if (append && selection.items.contains(item)) {
      return selection.deselect(item);
    }

    final success =
        selection.select(item, append: append, skipHandlers: skipHandlers);
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
    deathRow.forEach(core.removeObject);
    selection.clear();
    core.captureJournalEntry();
    return true;
  }

  bool undo() => core.undo();
  bool redo() => core.redo();

  Backboard _backboard;
  Backboard get backboard => _backboard;

  @override
  void onConnectionStateChanged(CoopConnectionStatus status) {
    /// We use this to handle changes that can come in during use. Right now we
    /// only handle showing the re-connecting (connecting) state.

    switch (status.state) {
      case CoopConnectionState.reconnectTimeout:
        _state = OpenFileState.timeout;
        _nextConnectionAttempt = status.nextConnectionAttempt;
        stateChanged.notify();
        break;
      case CoopConnectionState.connecting:
        _state = OpenFileState.loading;
        stateChanged.notify();
        break;
      case CoopConnectionState.connected:
        _state = OpenFileState.open;
        if (!fileInitialized) {
          completeInitialConnection(OpenFileState.open);
          fileInitialized = true;
          break;
        } else {
          _resetManagers();
          if (_sleepData != null) {
            selection.selectMultiple(_sleepData.selection
                .map((id) => core.resolve<Component>(id)?.stageItem)
                .where((item) => item != null));

            _sleepData = null;
          }

          core.advance(0);
          stateChanged.notify();
          delaySleep();
        }
        break;
      default:
        // This happens on disconnect, we should not notify if we're
        // intentionally disconnecting to sleep (we don't want to darken the
        // screen as soon as we disconnect for sleep). We want the user to be
        // able to refer back to this window and see unaltered content until
        // they interact with it again.
        if (_state != OpenFileState.sleeping) {
          stateChanged.notify();
        }
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
    if (action == ShortcutAction.showActions) {
      addAlert(
        ActionAlert(
            // Inverted logic as the toggle happens right after this, so !value
            // means it will be activated.
            !ShortcutAction.showActions.value
                ? 'Show Actions: ON'
                : 'Show Actions: OFF'),
      );
    } else if (_handleAction(action)) {
      if (ShortcutAction.showActions.value) {
        addAlert(
          ActionAlert('ACTION ${action.name}'),
        );
      }
      return true;
    }
    return false;
  }

  bool _handleAction(ShortcutAction action) {
    // See if any of our handlers care.
    // https://www.youtube.com/watch?v=1o4s1KVJaVA
    for (final actionHandler in _actionHandlers.reversed) {
      if (actionHandler(action)) {
        return true;
      }
    }
    // No one gives a F#$(C<, let's see if we can help this poor friend.
    switch (action) {
      case ShortcutAction.deselect:
        selection.clear();
        return true;
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

      case ShortcutAction.boneTool:
        stage?.tool = BoneTool.instance;
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

      case ShortcutAction.resetRulers:
        // TODO: Reset rulers.
        return true;

      case ShortcutAction.toggleRulers:
        stage?.showRulers = !stage.showRulers;
        return true;

      case ShortcutAction.cancel:
        // Default back to the select tool
        if (_upTheRabbitHole()) {
          stage?.tool = AutoTool.instance;
          Popup.closeAll();
        }
        return true;
      case ShortcutAction.navigateTreeLeft:
        return _upTheRabbitHole();

      case ShortcutAction.navigateTreeRight:
      case ShortcutAction.toggleEditMode:
        return _downTheRabbitHole();

      case ShortcutAction.navigateTreeDown:
        return _strafeRabbits(1);
      case ShortcutAction.navigateTreeUp:
        return _strafeRabbits(-1);

      case ShortcutAction.switchMode:
        switch (_mode.value) {
          case EditorMode.design:
            changeMode(EditorMode.animate);
            break;
          case EditorMode.animate:
            changeMode(EditorMode.design);
            break;
        }
        return true;

      default:
        return false;
    }
  }

  /// Save an updated file name
  void changeFileName(String name) {
    updateName(name);
    FileManager().renameFile(file, name);
  }

  final ValueNotifier<RevisionManager> _revisionManager =
      ValueNotifier<RevisionManager>(null);
  ValueListenable<RevisionManager> get revisionManager => _revisionManager;
  StreamSubscription<RiveFile> _previewListener;
  StreamSubscription<RevisionDM> _selectPreviewListener;

  /// Show the revision history.
  void showRevisionHistory() {
    var old = _revisionManager.value;
    _previewListener?.cancel();
    _selectPreviewListener?.cancel();

    var revisionManager = RevisionManager(api: api, fileId: fileId);
    _revisionManager.value = revisionManager;

    _selectPreviewListener =
        revisionManager.selectedRevision.listen(_revisionSelected);
    _previewListener = revisionManager.preview.listen(_previewRevision);
    old?.dispose();
  }

  void _revisionSelected(RevisionDM revision) {
    if (revision == null) {
      return;
    }
    // TODO: Figure out how we want the stage & hierarchy to look while loading
    // a revision.
  }

  /// This gets set when a preview is currently being displayed. The Active
  /// Revision is the revision to return to when preview mode is canceled.
  RiveFile _activeRevision;
  void _previewRevision(RiveFile previewFile) {
    core.removeDelegate(this);

    // Don't disconnect core, keep it around so we can change the revision. But
    // only do it if the activeRevision is null, meaning we weren't already
    // previewing.
    _activeRevision ??= core;

    _stage.value?.dispose();

    core = previewFile;

    completeInitialConnection(OpenFileState.open);
  }

  void hideRevisionHistory() {
    _previewListener?.cancel();
    _selectPreviewListener?.cancel();
    var old = _revisionManager.value;
    _revisionManager.value = null;
    old?.dispose();

    // Remove the preview if we were previewing.
    if (_activeRevision == null) {
      return;
    }
    core.removeDelegate(this);
    _stage.value?.dispose();
    core = _activeRevision;
    _activeRevision = null;
    completeInitialConnection(OpenFileState.open);
  }

  // TODO: remove these and do new darkening logic...
  SimpleAlert _restoringAlert;
  LabeledAlert _labeledAlert;

  void restoreRevision(RevisionDM revision) {
    assert(_activeRevision != null, 'not previewing a revision');
    _activeRevision.restoreRevision(revision.id);
    hideRevisionHistory();
    addAlert(_restoringAlert =
        SimpleAlert('Restoring revision...', autoDismiss: false));
  }

  StreamSubscription<AnimationViewModel> _selectedAnimationSubscription;

  // The active artboard may have changed, sync up the animation managers, or
  // anything that depends on active artboard.
  void _syncActiveArtboard() {
    _activeArtboard.value = _backboard.activeArtboard;
    // The artboard being animated is determined by whether the mode is animate
    // mode and the backboard has an active artboard.
    var animatingArtboard =
        mode.value == EditorMode.design || _backboard.activeArtboard == null
            ? null
            : _backboard.activeArtboard;
    if (_animationsManager.value?.activeArtboard == animatingArtboard) {
      return;
    }
    _selectedAnimationSubscription?.cancel();
    _selectedAnimationSubscription = null;
    _animationsManager.value?.dispose();
    if (animatingArtboard == null) {
      _animationsManager.value = null;
      _syncEditingAnimation(null);
      return;
    }

    var manager = _animationsManager.value =
        AnimationsManager(activeArtboard: _backboard.activeArtboard);
    _selectedAnimationSubscription =
        manager.selectedAnimation.listen(_syncEditingAnimation);
  }

  void _syncEditingAnimation(AnimationViewModel model) {
    LinearAnimation animation = model?.animation is LinearAnimation
        ? model.animation as LinearAnimation
        : null;
    if (_editingAnimationManager.value?.animation == animation) {
      return;
    }
    _editingAnimationManager.value?.dispose();
    _keyFrameManager.value?.dispose();

    if (animation == null) {
      _keyFrameManager.value = null;
      _editingAnimationManager.value = null;
    } else {
      _keyFrameManager.value = KeyFrameManager(animation, this);
      _editingAnimationManager.value = EditingAnimationManager(
        animation,
        this,
        selectedFrameStream: _keyFrameManager.value?.selection,
        changeSelectedFrameStream: _keyFrameManager.value?.changeSelection,
      );
    }
  }

  ContainerComponent _highestSelection() {
    var inspectionSet = InspectionSet.fromSelection(this, selection.items);
    int depth = double.maxFinite.toInt();
    ContainerComponent highest;
    for (final component in inspectionSet.components) {
      if (component is! ContainerComponent) {
        continue;
      }
      var currentDepth = component.computeDepth();
      if (
          // Component is highest we've found so far
          currentDepth < depth ||
              // or it's at the same level but its child order is lower
              currentDepth == depth &&
                  highest.childOrder.compareTo(component.childOrder) > 0) {
        depth = currentDepth;
        highest = component as ContainerComponent;
      }
    }
    return highest;
  }

  bool _strafeRabbits(int direction) {
    var highest = _highestSelection();
    // If we don't have a parent, we can't have siblings... (artboards ain't
    // rabbits!)
    if (highest != null && highest.parent != null) {
      // Pick valid siblings (that are on the stage and hence selectable).
      var siblings = highest.parent.children
          .where((sibling) =>
              sibling.stageItem != null && sibling.stageItem.stage != null)
          .toList(growable: false);

      if (siblings.length <= 1) {
        return false;
      }
      var sibling = siblings[
          ((siblings.indexOf(highest) + direction) + siblings.length) %
              siblings.length];
      selection.select(sibling.stageItem);
      showSelectionAlert('Selected ${sibling.name} '
          '(${RiveCoreContext.objectName(sibling.coreType)})');
      return true;
    }
    return false;
  }

  bool _downTheRabbitHole() {
    var highest = _highestSelection();

    // Find first child with valid stage item and select it.
    if (highest != null) {
      for (final child in highest.children) {
        if (child.stageItem != null && child.stageItem.stage != null) {
          selection.select(child.stageItem);
          showSelectionAlert('Selected ${child.name} '
              '(${RiveCoreContext.objectName(child.coreType)})');
          break;
        }
      }
    }
    return true;
  }

  bool _upTheRabbitHole() {
    var inspectionSet = InspectionSet.fromSelection(this, selection.items);
    int depth = double.maxFinite.toInt();
    ContainerComponent highest;
    for (final component in inspectionSet.components) {
      var possibleSelection = component.parent;
      if (possibleSelection == null ||
          possibleSelection.stageItem == null ||
          possibleSelection.stageItem.stage == null) {
        // parent is either null, has no stage item, or isn't on the stage
        continue;
      }

      var currentDepth = possibleSelection.computeDepth();
      if (currentDepth < depth ||
          // or it's at the same level but its child order is lower
          currentDepth == depth &&
              highest.childOrder.compareTo(possibleSelection.childOrder) > 0) {
        depth = currentDepth;
        highest = possibleSelection;
      }
    }
    if (highest != null) {
      selection.select(highest.stageItem);
      showSelectionAlert('Selected ${highest.name} '
          '(${RiveCoreContext.objectName(highest.coreType)})');
      return true;
    } else if (selection.isNotEmpty) {
      showSelectionAlert('Selection cleared');
      selection.clear();
      return true;
    }
    return false;
  }

  void _labelAlertDismissed(EditorAlert alert) {
    alert.dismissed.removeListener(_labelAlertDismissed);
    if (alert == _labeledAlert) {
      _labeledAlert = null;
    }
  }

  void showSelectionAlert(String label) {
    if (_labeledAlert == null) {
      addAlert(_labeledAlert = LabeledAlert(label, autoDismiss: true));
      _labeledAlert.dismissed.addListener(_labelAlertDismissed);
    } else {
      _labeledAlert.label = label;
    }
  }

  void _showPatchedAlert() {
    addAlert(LabeledAlert(
        'Rive had to patch up your file due to some bad data.',
        autoDismiss: true));
  }
}
