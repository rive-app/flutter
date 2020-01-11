import 'package:flutter/material.dart';
import 'package:rive_core/rive_file.dart';

import 'hierarchy_tree_controller.dart';
import 'selectable_item.dart';
import 'stage/stage.dart';

class Rive with RiveFileDelegate {
  final ValueNotifier<RiveFile> file = ValueNotifier<RiveFile>(null);
  final ValueNotifier<HierarchyTreeController> treeController =
      ValueNotifier<HierarchyTreeController>(null);
  final Set<SelectableItem> selectedItems = {};
  Stage _stage;

  void _changeFile(RiveFile nextFile) {
    file.value = nextFile;
    treeController.value = HierarchyTreeController(nextFile.artboards);
    selectedItems.clear();
    _stage?.dispose();
    _stage = Stage(this, file.value);
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
}
