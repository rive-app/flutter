import 'package:flutter/material.dart';
import 'package:rive_core/rive_file.dart';

import 'hierarchy_tree_controller.dart';
import 'package:rive_core/selectable_item.dart';
import 'stage/stage.dart';
import 'package:core/core.dart';

class Rive with RiveFileDelegate {
  final ValueNotifier<RiveFile> file = ValueNotifier<RiveFile>(null);
  final ValueNotifier<HierarchyTreeController> treeController =
      ValueNotifier<HierarchyTreeController>(null);
  final Set<SelectableItem> selectedItems = {};
  Stage _stage;

  void _changeFile(RiveFile nextFile) {
    file.value = nextFile;
    selectedItems.clear();
    _stage?.dispose();
    _stage = Stage(this, file.value);

    // Tree controller is based off of stage items.
    treeController.value = HierarchyTreeController(nextFile.artboards);
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
  }

  @override
  void onObjectAdded(Core object) {
    _stage.initComponent(object);
  }

}
