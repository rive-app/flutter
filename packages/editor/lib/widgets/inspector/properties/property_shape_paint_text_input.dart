import 'package:flutter/material.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_editor/widgets/common/converters/hex_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/percentage_input_converter.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';

/// The text input row underneath the color swatch for fills/strokes. Allows
/// inputting the color value (if it's a solid), the opacity, and the stroke
/// thickness (if it's a stroke).
class PropertyShapePaintTextInput extends StatelessWidget {
  static final _percentageConverter = PercentageInputConverter(0);

  final Iterable<ShapePaint> shapePaints;
  final InspectingColor inspectingColor;

  const PropertyShapePaintTextInput({
    @required this.shapePaints,
    @required this.inspectingColor,
    Key key,
  }) : super(key: key);

  String _disabledText(ColorType type) {
    switch (type) {
      case ColorType.linear:
        return 'Linear';
      case ColorType.radial:
        return 'Radial';
      default:
        return 'Mixed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: inspectingColor.type,
      builder: (context, ColorType type, child) => ValueListenableBuilder(
        valueListenable: inspectingColor.editingColor,
        builder: (context, HSVColor hsv, child) {
          return Padding(
            padding:
                const EdgeInsets.only(top: 5, bottom: 5, left: 45, right: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 12,
                  child: InspectorTextField(
                    value: hsv,
                    converter: HexValueConverter.instance,
                    disabledText: _disabledText(type),
                    change: type == ColorType.solid
                        ? inspectingColor.changeColor
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 11,
                  child: ValueListenableBuilder(
                    valueListenable: inspectingColor.opacity,
                    builder: (context, double opacity, _) => InspectorTextField(
                      value: opacity,
                      converter: _percentageConverter,
                      change: inspectingColor.changeOpacity,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10,
                  child: shapePaints.isNotEmpty && shapePaints.first is Stroke
                      ? CoreTextField(
                          objects: shapePaints,
                          propertyKey: StrokeBase.thicknessPropertyKey,
                          converter: TranslationValueConverter.instance,
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
