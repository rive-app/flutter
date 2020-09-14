import 'package:core/id.dart';
import 'package:rive_core/draw_rules.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/src/generated/draw_target_base.dart';
import 'package:rive_core/component_dirt.dart';
export 'package:rive_core/src/generated/draw_target_base.dart';

enum DrawTargetPlacement { before, after }

class DrawTarget extends DrawTargetBase {
  // Store first and last drawables that are affected by this target.
  Drawable first;
  Drawable last;

  // -> editor-only
  /// TODO: hook this up so we show it in the inspector when the draw rule
  /// causes a cyclic dependency.
  bool isValid = true;
  // <- editor-only

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

  DrawTargetPlacement get placement =>
      DrawTargetPlacement.values[placementValue];
  set placement(DrawTargetPlacement value) => placementValue = value.index;

  @override
  void drawableIdChanged(Id from, Id to) {
    _drawable = context?.resolve(to);
    // -> editor-only
    artboard?.markNaturalDrawOrderDirty();
    addDirt(ComponentDirt.naturalDrawOrder);
    // <- editor-only
  }

  @override
  void onAddedDirty() {
    super.onAddedDirty();
    if (drawableId != null) {
      _drawable = context?.resolve(drawableId);
    } else {
      _drawable = null;
    }
  }

  @override
  void placementValueChanged(int from, int to) {
    artboard?.markDrawOrderDirty();
  }

  @override
  void update(int dirt) {}

  // -> editor-only
  @override
  bool validate() => super.validate() && parent is DrawRules;

  @override
  String get defaultName {
    var index = (parent as DrawRules)?.targets?.toList()?.indexOf(this) ?? 0;
    return 'Draw Rule ${index + 1}';
  }
  // <- editor-only
}
