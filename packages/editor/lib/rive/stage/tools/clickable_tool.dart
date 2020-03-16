import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';

mixin ClickableTool {
  void onClick(Artboard activeArtboard, Vec2D worldMouse);
}
