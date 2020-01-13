import 'package:flutter/rendering.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';

import '../rive.dart';
import 'aabb_tree.dart';
import 'stage_item.dart';

typedef _ItemFactory = StageItem Function();

class Stage {
  final Rive rive;
  final RiveFile riveFile;
  // final Set<StageItem> items = {};
  final AABBTree<StageItem> visTree = AABBTree<StageItem>();

  Stage(this.rive, this.riveFile) {
    for (final object in riveFile.objects.values) {
      initComponent(object);
    }
  }

  /// Register a Core object with the stage.
  void initComponent(Component component) {
    var stageItemFactory = _factories[component.coreType];
    assert(stageItemFactory != null,
        "Factory shouldn't be null for component $component with type key ${component.coreType}");
    if (stageItemFactory != null) {
      var stageItem = stageItemFactory();
      if (stageItem != null && stageItem.initialize(component)) {
        component.stageItem = stageItem;
        addItem(stageItem);
      }
    }
  }

  void updateBounds(StageItem item) {
    visTree.placeProxy(item.visTreeProxy, item.aabb);
  }

  bool addItem(StageItem item) {
    assert(item != null);
    if (item.visTreeProxy != NullNode) {
      return false;
    }

    // items.add(item);
    item.visTreeProxy = visTree.createProxy(item.aabb, item);
    return true;
  }

  bool removeItem(StageItem item) {
    assert(item != null);
    if (item.visTreeProxy == NullNode) {
      return false;
    }

    visTree.destroyProxy(item.visTreeProxy);
    item.visTreeProxy = NullNode;
    return true;
  }

  void dispose() {}

  void _onFileChanged() {}

  void paint(PaintingContext context, Offset offset, Size size) {}

  final Map<int, _ItemFactory> _factories = {
    ArtboardBase.typeKey: () => StageArtboard(),
    NodeBase.typeKey: () => StageNode(),
  };
}
