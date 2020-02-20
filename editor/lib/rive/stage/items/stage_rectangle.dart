import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_editor/rive/inspectable.dart';

import '../stage_item.dart';

class StageRectangle extends StageItem<Rectangle> with BoundsDelegate {
  @override
  AABB get aabb => component.shape.bounds;

  @override
  void boundsChanged() {
    assert(stage != null);
    stage.updateBounds(this);
  }

  @override
  Set<InspectorBase> get inspectorItems => {
        InspectorItem(name: 'Pos', propertyKeys: [
          NodeBase.xPropertyKey,
          NodeBase.yPropertyKey,
        ]),
        InspectorItem(name: 'Size', propertyKeys: [
          ParametricPathBase.widthPropertyKey,
          ParametricPathBase.heightPropertyKey,
        ])
      };
}
