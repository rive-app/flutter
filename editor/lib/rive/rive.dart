import 'package:flutter/material.dart';
import 'package:rive_core/rive_file.dart';

import 'hierarchy_tree_controller.dart';

class Rive implements RiveFileDelegate {
  final ValueNotifier<RiveFile> file = ValueNotifier<RiveFile>(null);
  final ValueNotifier<HierarchyTreeController> treeController =
      ValueNotifier<HierarchyTreeController>(null);

  void _changeFile(RiveFile nextFile) {
    file.value = nextFile;
    treeController.value = HierarchyTreeController(nextFile.artboards);
  }

  /// Open a Rive file with a specific id. Ids are composed of owner_id:file_id.
  Future<RiveFile> open(String id) async {
    var opening = RiveFile(id, delegate: this);
    _changeFile(opening);
    return opening;
  }

  @override
  void onArtboardsChanged() {
    treeController.value.flatten();
  }
}
