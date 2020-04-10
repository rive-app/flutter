import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/converters/alpha_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/hex_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/percentage_input_converter.dart';
import 'package:rive_editor/widgets/common/converters/string_value_converter.dart';
import 'package:rive_editor/widgets/common/core_combo_box.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/color/inspector_color_swatch.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_component.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_title.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
import 'package:utilities/list_equality.dart';

class PropertyShapePaintTextInput extends StatelessWidget {
  static final percentageConverter = PercentageInputConverter(0);

  final Iterable<ShapePaint> shapePaints;
  final InspectingColor inspectingColor;
  final bool isStroke;

  const PropertyShapePaintTextInput({
    @required this.shapePaints,
    @required this.inspectingColor,
    this.isStroke = false,
    Key key,
  }) : super(key: key);

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
                      disabledText: 'Multiple',
                      change: type == null ? null : inspectingColor.changeColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 11,
                    child: ValueListenableBuilder(
                      valueListenable: inspectingColor.opacity,
                      builder: (context, double opacity, _) =>
                          InspectorTextField(
                        value: opacity,
                        converter: percentageConverter,
                        change: inspectingColor.changeOpacity,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 10,
                    child: isStroke
                        ? InspectorTextField(
                            value: hsv,
                            converter: HexValueConverter.instance,
                            change: type == null
                                ? null
                                : inspectingColor.changeColor,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            );
          }),
    );
  }
}
