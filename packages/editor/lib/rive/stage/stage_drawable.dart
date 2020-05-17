import 'dart:ui';

/// Abstract representation of anything that can draw on the stage.
abstract class StageDrawable {
  bool get drawsInWorldSpace;
  int get drawOrder;
  void draw(Canvas canvas);
}
