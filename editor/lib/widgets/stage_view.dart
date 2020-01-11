import 'package:flutter/material.dart';
import '../rive/rive.dart';

/// Draws a path with custom paint and a nuge property.
class StageView extends LeafRenderObjectWidget {
  /// The Rive context.
  final Rive rive;

  const StageView(this.rive);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _StageViewRenderObject()..rive = rive;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _StageViewRenderObject renderObject) {
    renderObject..rive = rive;
  }

  @override
  void didUnmountRenderObject(covariant _StageViewRenderObject renderObject) {
    // Any cleanup to do here?
  }
}

class _StageViewRenderObject extends RenderBox {
  Rive _rive;

  Rive get rive => _rive;
  set rive(Rive value) {
    if (_rive == value) {
      return;
    }
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    
  }
}
