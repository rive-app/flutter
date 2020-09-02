import 'package:rive_core/bones/weight.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/shapes/straight_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/straight_vertex_base.dart';

class StraightVertex extends StraightVertexBase {
  Weight _weight;

  @override
  String toString() => 'x[$x], y[$y], r[$radius]';

  @override
  void radiusChanged(double from, double to) {
    path?.markPathDirty();
  }

  @override
  void childAdded(Component component) {
    super.childAdded(component);
    if (component is Weight) {
      _weight = component;
    }
  }

  @override
  void childRemoved(Component component) {
    super.childRemoved(component);
    if (_weight == component) {
      _weight = null;
    }
  }

  @override
  Vec2D get renderTranslation =>
      _weight?.translation ?? super.renderTranslation;

  // -> editor-only
  @override
  void cloneWeight(Weight from) {
    if (from.coreType == WeightBase.typeKey) {
      appendChild(from);
    } else {
      initWeight();
      weight.indices = from.indices;
      weight.values = from.values;
      from.remove();
    }
  }

  @override
  void initWeight() {
    assert(context != null && context.isBatchAdding);
    var weight = Weight();
    context.addObject(weight);
    appendChild(weight);
  }
  // <- editor-only
}
