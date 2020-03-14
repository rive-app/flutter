import 'package:flutter/material.dart';
import 'package:rive_core/src/generated/shapes/paint/fill_base.dart';

/// A fill Shape painter.
class Fill extends FillBase {
  Fill() {
    paint.style = PaintingStyle.fill;
  }

  @override
  void update(int dirt) {
    // Intentionally empty, fill doesn't update.
    // Because Fill never adds dependencies, it'll also never get called.
  }
}
