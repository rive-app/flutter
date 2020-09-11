import 'package:core/id.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/src/generated/draw_target_base.dart';
import 'package:rive_core/component_dirt.dart';
export 'package:rive_core/src/generated/draw_target_base.dart';

class DrawTarget extends DrawTargetBase {
  Drawable _drawable;
  Drawable get drawable => _drawable;
  set drawable(Drawable value) {
    if (_drawable == value) {
      return;
    }

    // -> editor-only

    // Handle when a shape is deleted. #1177
    _drawable?.cancelWhenRemoved(remove);
    value?.whenRemoved(remove);

    // <- editor-only

    _drawable = value;
    drawableId = value?.id;
  }

  @override
  void drawableIdChanged(Id from, Id to) {
    _drawable = context?.resolve(to);
    artboard?.markNaturalDrawOrderDirty();
    addDirt(ComponentDirt.naturalDrawOrder);
  }

  @override
  void placementValueChanged(int from, int to) {
    artboard?.markDrawOrderDirty();
  }

  @override
  void update(int dirt) {}
}
