import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/inspectable.dart';

import '../stage_item.dart';

class StageShape extends StageItem<Shape> with BoundsDelegate {
  @override
  AABB get aabb => component.bounds;

  @override
  void boundsChanged() {
    assert(stage != null);
    stage.updateBounds(this);
  }

  @override
  void paint(Canvas canvas) {
    // Write now the StageShape draws the shape itself, this needs to be moved
    // to the drawable shape component. The only painting the StageShape will do
    // is when the item is selected.
    canvas.drawPath(
        component.uiPath,
        Paint()
          ..color = selectionState.value == SelectionState.none
              ? const Color.fromRGBO(100, 100, 100, 1.0)
              : const Color.fromRGBO(200, 200, 200, 1.0));
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
          ],
        ),
        InspectorGroup(
          name: null,
          children: [
            InspectorItem(
              name: 'Opacity',
              properties: [
                InspectorProperty(
                  key: NodeBase.opacityPropertyKey,
                ),
              ],
            ),
          ],
        ),
        InspectorGroup(
          name: 'Bind Bones',
          canAdd: true,
          children: [],
        ),
        InspectorGroup(
          name: 'Masks',
          canAdd: true,
          children: [],
        ),
        InspectorGroup(
          name: 'Clipping Paths',
          canAdd: true,
          children: [],
        ),
        InspectorGroup(
          name: 'Effects',
          canAdd: true,
          children: [],
        ),
        InspectorGroup(
          name: 'Constraints',
          canAdd: true,
          children: [],
        ),
        InspectorGroup(
          name: 'Events',
          canAdd: true,
          children: [],
        ),
        InspectorGroup(
          name: 'Custom Properties',
          canAdd: true,
          children: [],
        ),
      };
}
