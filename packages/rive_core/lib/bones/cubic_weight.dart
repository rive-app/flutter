import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/src/generated/bones/cubic_weight_base.dart';
export 'package:rive_core/src/generated/bones/cubic_weight_base.dart';

class CubicWeight extends CubicWeightBase {
  final Vec2D inTranslation = Vec2D();
  final Vec2D outTranslation = Vec2D();

  @override
  void inIndicesChanged(int from, int to) {
    // -> editor-only
    invalidateDeform();
    // <- editor-only
  }

  @override
  void inValuesChanged(int from, int to) {
    // -> editor-only
    invalidateDeform();
    // <- editor-only
  }

  @override
  void outIndicesChanged(int from, int to) {
    // -> editor-only
    invalidateDeform();
    // <- editor-only
  }

  @override
  void outValuesChanged(int from, int to) {
    // -> editor-only
    invalidateDeform();
    // <- editor-only
  }

  // -> editor-only
  @override
  bool validate() {
    return parent is CubicVertex;
  }
  // <- editor-only
}
