// -> editor-only
import 'package:flutter/foundation.dart';
import 'package:rive_core/math/mat2d.dart';

abstract class StageTransformable {
  Listenable get worldTransformChanged;

  /// The transform in the object's hierarchy root, sometimes referred to as the
  /// artboard transform in Rive.
  Mat2D get worldTransform;

  // set worldTransform(Mat2D value);

  /// The transform in the context of the entire scene graph, sometimes referred
  /// to as the backboard transform in Rive.
  Mat2D get renderTransform;
}
// <- editor-only
