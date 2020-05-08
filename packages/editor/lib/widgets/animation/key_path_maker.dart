import 'dart:math';
import 'dart:ui';

import 'package:rive_core/math/mat2d.dart';
import 'package:rive_editor/widgets/theme.dart';

void makeKeyPath(Path keyPath, RiveThemeData theme, Offset offset,
    {double rotation = pi / 4, double padRadius = 0}) {
  var keyRadius = theme.dimensions.keyHalfSquare + padRadius;
  var transform = Mat2D();
  Mat2D.fromRotation(transform, rotation);
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
