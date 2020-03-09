/// Core automatically generated lib/src/generated/shapes/ellipse_base.dart.
/// Do not modify manually.

import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/node_base.dart';
import 'package:rive_core/src/generated/shapes/parametric_path_base.dart';
import 'package:rive_core/src/generated/shapes/path_base.dart';

abstract class EllipseBase extends ParametricPath {
  static const int typeKey = 4;
  @override
  int get coreType => EllipseBase.typeKey;
  @override
  Set<int> get coreTypes => {
        EllipseBase.typeKey,
        ParametricPathBase.typeKey,
        PathBase.typeKey,
        NodeBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };
}
