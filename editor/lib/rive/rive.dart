import 'package:core/coop/connect_result.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';

import 'file_browser/file_browser.dart';
import 'hierarchy_tree_controller.dart';
import 'selection_context.dart';
import 'stage/stage.dart';
import 'stage/stage_item.dart';

class Rive with RiveFileDelegate {
  final file = ValueNotifier<RiveFile>(null);
  final treeController = ValueNotifier<HierarchyTreeController>(null);
  final selection = SelectionContext<SelectableItem>();
  final selectionMode = ValueNotifier<SelectionMode>(SelectionMode.single);
  final fileBrowser = FileBrowser();
  final tabs = ValueNotifier<List<RiveTabItem>>([
    RiveTabItem(name: "Guido's Files", closeable: false),
    RiveTabItem(name: "Ellipse Testing"),
    RiveTabItem(name: "Spaceman"),
  ]);
  final selectedTab = ValueNotifier<RiveTabItem>(null);


  Stage _stage;
  Stage get stage => _stage;

  void _changeFile(RiveFile nextFile) {
    file.value = nextFile;
    selection.clear();
    _stage?.dispose();
    _stage = Stage(this, file.value);
    _stage.tool = TranslateTool();

    // Tree controller is based off of stage items.
    treeController.value =
        HierarchyTreeController(nextFile.artboards, rive: this);
  }

  /// Open a Rive file with a specific id. Ids are composed of owner_id:file_id.
  Future<RiveFile> open(String id) async {
    var opening = RiveFile(id);
    opening.addDelegate(this);
    _changeFile(opening);
    final _tab = RiveTabItem(name: id);
    if (!tabs.value.map((t) => t.name).contains(id)) {
      tabs.value.add(_tab);
    }
    openTab(_tab);
    return opening;
  }

  final ValueNotifier<SelectionMode> selectionMode =
      ValueNotifier<SelectionMode>(SelectionMode.single);

  final ValueNotifier<Stage> stage = ValueNotifier<Stage>(null);
  Stage _stage;


  void closeTab(RiveTabItem value) {
    tabs.value.remove(value);
    selectedTab.value = tabs.value.last;
  }

  void openTab(RiveTabItem value) {
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

    // Tree controller is based off of stage items.
    treeController.value =
        HierarchyTreeController(nextFile.artboards, rive: this);
  }
}

enum SelectionMode { single, multi, range }
