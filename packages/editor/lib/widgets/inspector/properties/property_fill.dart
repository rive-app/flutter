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
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_title.dart';

/// Uses the InspectorPopoutComponent to build a row in the inspector for
/// editing a color fill on a shape.
class PropertyFill extends StatelessWidget {
  final Iterable<ShapePaint> fills;
  final InspectingColor inspectingColor;

  const PropertyFill({
    @required this.fills,
    @required this.inspectingColor,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectorPopoutComponent(
      components: fills,
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
          const InspectorPopoutTitle(title: 'FILL OPTIONS'),
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
                  objects: fills,
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
                'Fill Rule',
                style: RiveTheme.of(context).textStyles.inspectorPropertyLabel,
              ),
              const SizedBox(width: 20),
              CoreComboBox(
                sizing: ComboSizing.expanded,
                objects: fills,
                propertyKey: FillBase.fillRulePropertyKey,
                options: PathFillType.values,
                toLabel: (PathFillType fillType) {
                  switch (fillType) {
                    case PathFillType.evenOdd:
                      return 'Even-Odd';
                    case PathFillType.nonZero:
                      return 'Non-Zero';
                  }
                  return '-';
                },
                toCoreValue: (PathFillType fillType) => fillType.index,
                fromCoreValue: (int value) => PathFillType.values[value],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
