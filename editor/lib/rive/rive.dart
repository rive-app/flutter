import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/stage/tools/translate_tool.dart';

import 'file_browser/file.dart';
import 'hierarchy_tree_controller.dart';
import 'package:rive_core/selectable_item.dart';
import 'selection_context.dart';
import 'stage/stage.dart';
import 'package:core/core.dart';

enum SelectionMode { single, multi, range }

class Rive with RiveFileDelegate {
  final ValueNotifier<RiveFile> file = ValueNotifier<RiveFile>(null);
  final ValueNotifier<HierarchyTreeController> treeController =
      ValueNotifier<HierarchyTreeController>(null);
  final Set<SelectableItem> selectedItems = {};
  final Set<FileItem> openFiles = {};
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
    return opening;
  }

  @override
  void onArtboardsChanged() {
    treeController.value.flatten();
    // TODO: this will get handled by dependency manager.
    _stage.markNeedsAdvance();
  }

  @override
  void onObjectAdded(Core object) {
    _stage.initComponent(object);
  }
}
