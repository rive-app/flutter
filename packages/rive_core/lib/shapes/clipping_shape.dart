import 'package:core/id.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/clipping_shape_base.dart';

enum ClipOp { difference, intersection }

class ClippingShape extends ClippingShapeBase {
  ClipOp get clipOp => ClipOp.values[clipOpValue];
  set clipOp(ClipOp value) => clipOpValue = value.index;

  Shape _shape;
  Shape get shape => _shape;
  set shape(Shape value) {
    if (_shape == value) {
      return;
    }
    _shape = value;
    shapeId = value?.id;
  }

  @override
  void clipOpValueChanged(int from, int to) {
    // In the future, if clipOp can change at runtime (animation), we may want
    // the shapes that use this as a clipping source to make them depend on this
    // clipping shape so we can add dirt to them directly.
    parent.addDirt(ComponentDirt.clip);
  }

  @override
  void shapeIdChanged(Id from, Id to) {
    shape = context?.resolve(to);
  }

  @override
  void update(int dirt) {
    // Intentionally empty.
  }
}
