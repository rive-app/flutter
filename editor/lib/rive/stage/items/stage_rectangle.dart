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
        InspectorGroup(
          name: null,
          children: [
            InspectorItem(name: 'Position', properties: [
              InspectorProperty(key: NodeBase.xPropertyKey, label: 'X'),
              InspectorProperty(key: NodeBase.yPropertyKey, label: 'Y'),
            ]),
            InspectorItem(
              name: 'Scale',
              properties: [
                InspectorProperty(key: NodeBase.scaleXPropertyKey, label: 'X'),
                InspectorProperty(key: NodeBase.scaleYPropertyKey, label: 'Y'),
              ],
              linkable: true,
            ),
            InspectorItem(
              name: 'Rotate',
              properties: [
                InspectorProperty(
                  key: NodeBase.rotationPropertyKey,
                ),
              ],
              linkable: true,
            ),
            InspectorItem(
              name: 'Size',
              properties: [
                InspectorProperty(
                    key: ParametricPathBase.widthPropertyKey, label: 'Width'),
                InspectorProperty(
                    key: ParametricPathBase.heightPropertyKey, label: 'Height'),
              ],
              linkable: true,
            ),
          ],
        ),
        InspectorItem(name: 'Corner Radius', properties: [
          InspectorProperty(key: RectangleBase.cornerRadiusPropertyKey),
        ]),
      };
}
