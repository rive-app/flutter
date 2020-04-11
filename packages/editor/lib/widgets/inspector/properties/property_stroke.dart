import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/converters/string_value_converter.dart';
import 'package:rive_editor/widgets/common/core_combo_box.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
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
              Text(
                'Name',
                style: RiveTheme.of(context).textStyles.inspectorPropertyLabel,
              ),
              const SizedBox(width: 20),
              Expanded(
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
              Text(
                'Cap',
                style: RiveTheme.of(context).textStyles.inspectorPropertyLabel,
              ),
              const SizedBox(width: 20),
              CoreComboBox(
                sizing: ComboSizing.expanded,
                objects: strokes,
                propertyKey: StrokeBase.capPropertyKey,
                options: StrokeCap.values,
                toLabel: (StrokeCap strokeCap) {
                  switch (strokeCap) {
                    case StrokeCap.butt:
                      return 'Butt';
                    case StrokeCap.round:
                      return 'Round';
                    case StrokeCap.square:
                      return 'Square';
                  }
                  return '-';
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
              Text(
                'Join',
                style: RiveTheme.of(context).textStyles.inspectorPropertyLabel,
              ),
              const SizedBox(width: 20),
              CoreComboBox(
                sizing: ComboSizing.expanded,
                objects: strokes,
                propertyKey: StrokeBase.joinPropertyKey,
                options: StrokeJoin.values,
                toLabel: (StrokeJoin strokeJoin) {
                  switch (strokeJoin) {
                    case StrokeJoin.bevel:
                      return 'Bevel';
                    case StrokeJoin.round:
                      return 'Round';
                    case StrokeJoin.miter:
                      return 'Miter';
                  }
                  return '-';
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
              Text(
                'Transform Affects',
                style: RiveTheme.of(context).textStyles.inspectorPropertyLabel,
              ),
              const SizedBox(width: 20),
              CoreComboBox(
                sizing: ComboSizing.expanded,
                objects: strokes,
                propertyKey: StrokeBase.transformAffectsStrokePropertyKey,
                options: const [true, false],
                toLabel: (bool value) =>
                    value == null ? '-' : value ? 'True' : 'False',
                toCoreValue: (bool value) => value,
                fromCoreValue: (bool value) => value,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
