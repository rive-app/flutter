import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/inspectable.dart';

import '../stage_item.dart';

class StageNode extends StageItem<Node> {
  @override
  AABB get aabb => AABB.fromValues(0, 0, 1, 1);

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
      };
}
