import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';

/// Abstraction of the currently inspected color.
class InspectingColor {
  Iterable<ShapePaint> shapePaints;
  InspectingColor(this.shapePaints) {
    var first = shapePaints.first;
    if (first is SolidColor) {
      editingColor.value = HSVColor.fromColor((first as SolidColor).color);
    }
  }

  ValueNotifier<ColorType> type = ValueNotifier<ColorType>(ColorType.solid);
  ValueNotifier<List<HSVColor>> colors = ValueNotifier<List<HSVColor>>([]);
  ValueNotifier<int> editingIndex = ValueNotifier<int>(0);
  ValueNotifier<HSVColor> editingColor =
      ValueNotifier<HSVColor>(HSVColor.fromColor(const Color(0xFFFF0000)));

  /// Change the currently editing color
  void changeColor(HSVColor color) {
    editingColor.value = color;
    switch (type.value) {
      case ColorType.solid:
        _changeSolidColor(color.toColor());
        break;
      default:
        break;
    }
  }

  void _changeSolidColor(Color color) {
    var solidColors = shapePaints.whereType<SolidColor>();
    for (final solidColor in solidColors) {
      solidColor.color = color;
    }
  }

  void completeChange() {
    shapePaints.first.context?.captureJournalEntry();
  }
}

/// Color change callback used by the various color picker components.
typedef ChangeColor = void Function(HSVColor);
