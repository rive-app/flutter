import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/converters/string_value_converter.dart';
import 'package:rive_editor/widgets/common/core_combo_box.dart';
import 'package:rive_editor/widgets/common/core_editor_switch.dart';
import 'package:rive_editor/widgets/common/core_multi_toggle.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/common/multi_toggle.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/color/inspector_color_swatch.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_component.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_title.dart';

/// Uses the InspectorPopoutComponent to build a row in the inspector for
/// editing a color fill on a shape.
class PropertyStroke extends StatelessWidget {
  static const double inputWidth = 70;
  final Iterable<ShapePaint> strokes;
  final InspectingColor inspectingColor;

  const PropertyStroke({
    @required this.strokes,
    @required this.inspectingColor,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectorPopoutComponent(
      components: strokes,
      prefix: (context) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: InspectorColorSwatch(
          inspectorContext: context,
          inspectingColor: inspectingColor,
        ),
      ),
      isVisiblePropertyKey: ShapePaintBase.isVisiblePropertyKey,
      popoutBuilder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InspectorPopoutTitle(title: 'STROKE OPTIONS'),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Text(
                  'Name',
                  style:
                      RiveTheme.of(context).textStyles.inspectorPropertyLabel,
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: inputWidth,
                child: CoreTextField(
                  objects: strokes,
                  propertyKey: ComponentBase.namePropertyKey,
                  converter: StringValueConverter.instance,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Text(
                  'Cap',
                  style:
                      RiveTheme.of(context).textStyles.inspectorPropertyLabel,
                ),
              ),
              const SizedBox(width: 20),
              CoreMultiToggle(
                objects: strokes,
                propertyKey: StrokeBase.capPropertyKey,
                options: const [
                  StrokeCap.butt,
                  StrokeCap.round,
                  StrokeCap.square,
                ],
                toIcon: (StrokeCap cap) {
                  switch (cap) {
                    case StrokeCap.butt:
                      return 'cap-none';
                    case StrokeCap.round:
                      return 'cap-round';
                    case StrokeCap.square:
                      return 'cap-square';
                  }
                  return null;
                },
                toCoreValue: (StrokeCap strokeCap) => strokeCap.index,
                fromCoreValue: (int value) => StrokeCap.values[value],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Text(
                  'Join',
                  style:
                      RiveTheme.of(context).textStyles.inspectorPropertyLabel,
                ),
              ),
              const SizedBox(width: 20),
              CoreMultiToggle(
                objects: strokes,
                propertyKey: StrokeBase.joinPropertyKey,
                options: const [
                  StrokeJoin.round,
                  StrokeJoin.bevel,
                  StrokeJoin.miter,
                ],
                toIcon: (StrokeJoin strokeJoin) {
                  switch (strokeJoin) {
                    case StrokeJoin.bevel:
                      return 'join-bevel';
                    case StrokeJoin.round:
                      return 'join-round';
                    case StrokeJoin.miter:
                      return 'join-miter';
                  }
                  return null;
                },
                toCoreValue: (StrokeJoin strokeJoin) => strokeJoin.index,
                fromCoreValue: (int value) => StrokeJoin.values[value],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Text(
                  'Transform Affects',
                  style:
                      RiveTheme.of(context).textStyles.inspectorPropertyLabel,
                ),
              ),
              const SizedBox(width: 20),
              CoreEditorSwitch(
                objects: strokes,
                propertyKey: StrokeBase.transformAffectsStrokePropertyKey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
