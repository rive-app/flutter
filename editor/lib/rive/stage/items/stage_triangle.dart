import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/triangle.dart';
import 'package:rive_editor/rive/inspectable.dart';

import '../stage_item.dart';

class StageTriangle extends StageItem<Triangle> with BoundsDelegate {
  @override
  AABB get aabb => component.shape.bounds;

  @override
  void boundsChanged() {
    assert(stage != null);
    stage.updateBounds(this);
  }

  @override
  Set<InspectorBase> get inspectorItems => {
        InspectorGroup(
          name: null,
          children: [
            InspectorItem(name: 'Position', properties: [
              InspectorProperty(key: NodeBase.xPropertyKey, label: 'X'),
              InspectorProperty(key: NodeBase.yPropertyKey, label: 'Y'),
            ]),
            InspectorItem(name: 'Scale', properties: [
              InspectorProperty(key: NodeBase.scaleXPropertyKey, label: 'X'),
              InspectorProperty(key: NodeBase.scaleYPropertyKey, label: 'Y'),
            ]),
            InspectorItem(name: 'Rotate', properties: [
              InspectorProperty(
                key: NodeBase.rotationPropertyKey,
              ),
            ]),
            InspectorItem(name: 'Size', properties: [
              InspectorProperty(
                  key: ParametricPathBase.widthPropertyKey, label: 'Width'),
              InspectorProperty(
                  key: ParametricPathBase.heightPropertyKey, label: 'Height'),
            ]),
          ],
        ),
      };
}
