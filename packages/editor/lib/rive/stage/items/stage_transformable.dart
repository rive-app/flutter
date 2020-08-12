// -> editor-only
import 'package:flutter/foundation.dart';
import 'package:rive_core/math/mat2d.dart';

class TransformFlags {
  static const int x = 1 << 0;
  static const int y = 1 << 1;
  static const int rotation = 1 << 2;
  static const int scaleX = 1 << 3;
  static const int scaleY = 1 << 4;
  static const int all = x | y | rotation | scaleX | scaleY;
}

abstract class StageTransformable {
  Listenable get worldTransformChanged;

  /// The transform in the object's hierarchy root, sometimes referred to as the
  /// artboard transform in Rive.
  Mat2D get worldTransform;

  // set worldTransform(Mat2D value);

  /// The transform in the context of the entire scene graph, sometimes referred
  /// to as the backboard transform in Rive.
  Mat2D get renderTransform;

  /// Return which transforms this transformable can accomodate.
  int get transformFlags;
}
// <- editor-only