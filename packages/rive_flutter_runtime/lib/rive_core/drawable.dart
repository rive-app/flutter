import 'dart:ui';
import 'package:rive/src/generated/drawable_base.dart';
export 'package:rive/src/generated/drawable_base.dart';

abstract class Drawable extends DrawableBase {
  void draw(Canvas canvas);
  @override
  void blendModeChanged(int from, int to) {}
  @override
  void drawOrderChanged(int from, int to) {
    artboard?.markDrawOrderDirty();
  }
}
