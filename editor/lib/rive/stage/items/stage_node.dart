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
          ],
        ),
      };
}
