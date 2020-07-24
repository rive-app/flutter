import 'package:flutter/widgets.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_ellipse.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/items/stage_rectangle.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// StageItem icon usually displayed in a tree like the Hierarchy or the
/// Animation property tree. TODO: hook up real icons here (N.B. this requires
/// some level of abstraction with the StageItem as some items will return
/// simple icons and others will need to build an iconic representation of
/// themselves/their contents like the paths/shapes).
class StageItemIcon extends StatelessWidget {
  final StageItem item;

  const StageItemIcon({
    @required this.item,
    Key key,
  })  : assert(item != null, 'StageItem cannot be null'),
        super(key: key);

  Iterable<PackedIcon> _icon() {
    // Artboard
    if (item is StageArtboard) {
      return PackedIcon.artboard;
    }

    if (item is StageNode) {
      return PackedIcon.node;
    }
    if (item is StageRectangle) {
      return PackedIcon.rectangleSmall;
    }
    if (item is StageEllipse) {
      return PackedIcon.ellipseSmall;
    }
    if (item is StagePath) {
      return PackedIcon.curves;
    }

    if (item is StageShape) {
      // Determine if the shape holds a single parametric path and if so show
      // the icon for that
      final component = (item as StageShape).component;
      // Calculate the set of visible components in the shape
      final visibleChildren = component.children
          .where(
            (c) => c.stageItem != null && c.stageItem.showInHierarchy,
          )
          .toSet();
      if (visibleChildren.length == 1) {
        if (component.children.first is Rectangle) {
          return PackedIcon.rectangleSmall;
        } else if (component.children.first is Ellipse) {
          return PackedIcon.ellipseSmall;
        }
      }
      return PackedIcon.shapeSmall;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon();
    return icon != null
        ? TintedIcon(color: const Color(0xFF999999), icon: icon)
        : Container(
            decoration: const BoxDecoration(
              color: Color(0xFF999999),
              borderRadius: BorderRadius.all(
                Radius.circular(2),
              ),
            ),
          );
  }
}
