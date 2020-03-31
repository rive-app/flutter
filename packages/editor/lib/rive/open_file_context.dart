import 'package:core/coop/connect_result.dart';
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
import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';

enum OpenFileState { loading, error, open }

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
  final ValueNotifier<String> name;

  /// The Core representation of the file.
  RiveFile core;

  /// The Stage data for this file.
  Stage _stage;

  OpenFileState _state = OpenFileState.loading;

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
  final ValueNotifier<bool> isAnimateMode = ValueNotifier<bool>(false);

  OpenFileContext(
    this.ownerId,
    this.fileId, {
    this.rive,
    String fileName,
    this.api,
    this.filesApi,
  }) : name = ValueNotifier<String>(fileName);

  Stage get stage => _stage;

  OpenFileState get state => _state;
  final Event stateChanged = Event();

  Future<bool> connect() async {
    if (core != null) {
      // TODO: We're already connected, the user re-clicked on this tab.
      print('TODO: make sure Core connection is still open, maybe ping it?');
    } else {
      var spectre = api.cookies['spectre'];
      var urlEncodedSpectre = Uri.encodeComponent(spectre);
      var filePath = '$ownerId/$fileId/$urlEncodedSpectre';
      core = RiveFile(filePath, api: api);

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
      var stage = Stage(this);
      _stage = stage;
      _stage.tool = TranslateTool();
      _resetTreeControllers();
      stateChanged.notify();
    }
    return true;
  }

  void dispose() {
    core?.disconnect();
    _stage?.dispose();
  }

  /// Whether this file is the currently active file.
  bool get isActive => rive.file.value == this;

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
    debounce(treeController.value.flatten);
    debounce(drawOrderTreeController.value.flatten);
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
  void onObjectRemoved(covariant Component object) {
    if (object.stageItem != null) {
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
    _resetTreeControllers();
  }

  void _resetTreeControllers() {
    treeController.value = HierarchyTreeController(core.artboards, file: this);
    drawOrderTreeController.value = DrawOrderTreeController(
      DrawOrderManager(core.artboards).drawableComponentsInOrder,
      file: this,
    );
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
          component.applyToChildren((child) => deathRow.add(child));
        }
      }
    }
    if (deathRow.isEmpty) {
      return false;
    }
    deathRow.forEach(core.remove);
    selection.clear();
    core.captureJournalEntry();
    return true;
  }

  bool undo() => core.undo();
  bool redo() => core.redo();
}
