import 'dart:math';
import 'dart:ui';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_editor/widgets/theme.dart';

/// Create a styled path for the Rive keyframe.
mixin KeyPathMaker {
  final Path keyPath = Path();

  void makeKeyPath(RiveThemeData theme, Offset offset) {
    var keyRadius = theme.dimensions.keyHalfSquare;
    var transform = Mat2D();
    Mat2D.fromRotation(transform, pi / 4);
    keyPath.reset();
    keyPath.addPath(
      Path()
        ..addRect(
          Rect.fromLTRB(
            -keyRadius,
            -keyRadius,
            keyRadius,
            keyRadius,
          ),
        ),
      offset,
      matrix4: transform.mat4,
    );
  }
}
