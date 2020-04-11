/// Core automatically generated lib/src/generated/shapes/shape_base.dart.
/// Do not modify manually.

import 'package:rive_core/drawable.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/drawable_base.dart';
import 'package:rive_core/src/generated/node_base.dart';

abstract class ShapeBase extends Drawable {
  static const int typeKey = 3;
  @override
  int get coreType => ShapeBase.typeKey;
  @override
  Set<int> get coreTypes => {
        ShapeBase.typeKey,
        DrawableBase.typeKey,
        NodeBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };
}
