import 'dart:ui';

typedef DrawCallback = void Function(Canvas, StageDrawPass);

class StageDrawPass {
  /// StageItems can either draw in world space or screen space.
  final bool inWorldSpace;

  /// StageItems are sorted by [order] before being drawn. This allows
  /// specific classification of items to draw before/after others. For example,
  /// transform handles should always draw after other content.
  final int order;

  // The drawable to call draw on.
  final DrawCallback draw;

  const StageDrawPass(
    this.draw, {
    this.inWorldSpace,
    this.order,
  });

  int compareDrawOrderTo(StageDrawPass other) => order - other.order;
}

/// Abstract representation of anything that can draw on the stage.
abstract class StageDrawable {
  void draw(Canvas canvas, StageDrawPass drawPass);
  Iterable<StageDrawPass> get drawPasses;
}
