import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_editor/rive/inspectable.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/node.dart';

import '../stage_item.dart';

class StageEllipse extends StageItem<Ellipse> with BoundsDelegate {
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
            InspectorItem(name: 'Pos', properties: [
              InspectorProperty(key: NodeBase.xPropertyKey, label: 'x'),
              InspectorProperty(key: NodeBase.yPropertyKey, label: 'y'),
            ]),
            InspectorItem(name: 'Scale', properties: [
              InspectorProperty(key: NodeBase.scaleXPropertyKey, label: 'x'),
              InspectorProperty(key: NodeBase.scaleYPropertyKey, label: 'y'),
            ]),
            InspectorItem(name: 'Rotation', properties: [
              InspectorProperty(
                key: NodeBase.rotationPropertyKey,
              ),
            ]),
            InspectorItem(name: 'Size', properties: [
              InspectorProperty(
                  key: ParametricPathBase.widthPropertyKey, label: 'width'),
              InspectorProperty(
                  key: ParametricPathBase.heightPropertyKey, label: 'height'),
            ]),
          ],
        ),
      };
}
