
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';

/// Abstraction of the currently inspected color.
class InspectingColor {
  ValueNotifier<ColorType> type = ValueNotifier<ColorType>(ColorType.solid);
  ValueNotifier<List<HSVColor>> colors = ValueNotifier<List<HSVColor>>([]);
  ValueNotifier<int> editingIndex = ValueNotifier<int>(0);
  ValueNotifier<HSVColor> editingColor =
      ValueNotifier<HSVColor>(HSVColor.fromColor(const Color(0xFFFF0000)));
}

/// Color change callback used by the various color picker components.
typedef ChangeColor = void Function(HSVColor);
