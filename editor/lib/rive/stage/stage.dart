import 'package:flutter/rendering.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';
import 'package:core/core.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';

import '../rive.dart';
import 'aabb_tree.dart';
import 'stage_item.dart';

typedef _ItemFactory = StageItem Function();

class Stage {
  final Rive rive;
  final RiveFile riveFile;
  final Set<StageItem> items = {};
  final AABBTree<StageItem> visTree = AABBTree<StageItem>();

  Stage(this.rive, this.riveFile) {
    for (final object in riveFile.objects.values) {
      _initObject(object);
    }
  }

  /// Register a Core object with the stage.
  void _initObject(Core object) {
    var stageItemFactory = _factories[object.coreType];
    if (stageItemFactory != null) {
      var stageItem = stageItemFactory();
      if (stageItem != null && stageItem.initialize(object)) {
        addItem(stageItem);
      }
    }
  }

  void updateBounds(StageItem item) {
    visTree.placeProxy(item.visTreeProxy, item.aabb);
  }

  void addItem(StageItem item) {
    assert(item != null);
    
    items.add(item);
    item.visTreeProxy = visTree.createProxy(item.aabb, item);
  }

  void removeItem(StageItem item) {
    assert(item != null);

    visTree.destroyProxy(item.visTreeProxy);
    item.visTreeProxy = NullNode;
  }

  void dispose() {}

  void _onFileChanged() {}

  void paint(PaintingContext context, Offset offset, Size size) {}

  final Map<int, _ItemFactory> _factories = {
    NodeBase.typeKey: () => StageNode()
  };
}
