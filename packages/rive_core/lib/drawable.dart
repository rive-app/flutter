import 'dart:ui';

import 'package:core/core.dart';
import 'package:rive_core/src/generated/drawable_base.dart';
export 'package:rive_core/src/generated/drawable_base.dart';

abstract class Drawable extends DrawableBase {
  /// Draw the contents of this drawable component in world transform space.
  void draw(Canvas canvas);

  @override
  void blendModeChanged(int from, int to) {}

  @override
  void drawOrderChanged(FractionalIndex from, FractionalIndex to) {}
}
