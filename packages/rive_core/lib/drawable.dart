import 'dart:ui';

import 'package:core/core.dart';
import 'package:rive_core/src/generated/drawable_base.dart';
export 'package:rive_core/src/generated/drawable_base.dart';

abstract class Drawable extends DrawableBase {
  /// Draw the contents of this drawable component in world transform space.
  void draw(Canvas canvas);

  BlendMode get blendMode => BlendMode.values[blendModeValue];
  set blendMode(BlendMode value) => blendModeValue = value.index;
  
  @override
  void blendModeValueChanged(int from, int to) {}

  @override
  void drawOrderChanged(FractionalIndex from, FractionalIndex to) {
    artboard?.markDrawOrderDirty();
  }

  // -> editor-only
  @override
  int runtimeValueDrawOrder(FractionalIndex editorValue) {
    return artboard.drawables.indexOf(this);
  }
  // <- editor-only
}
