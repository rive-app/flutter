import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/widgets/common/converters/string_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/inspector_color_swatch.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_component.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_title.dart';

/// Uses the InspectorPopoutComponent to build a row in the inspector for
/// editing a color fill on a shape.
class PropertyFill extends StatelessWidget {
  final Iterable<Fill> fills;

  const PropertyFill({
    @required this.fills,
    Key key,
  }) : super(key: key);

  static const double inputWidth = 70;

  @override
  Widget build(BuildContext context) {
    return InspectorPopoutComponent(
      components: fills,
      prefix: (context) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: InspectorColorSwatch(
          inspectorContext: context,
          shapePaints: fills,
        ),
      ),
      isVisiblePropertyKey: ShapePaintBase.isVisiblePropertyKey,
      popoutBuilder: (context) => Column(
        // mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InspectorPopoutTitle(title: 'FILL OPTIONS'),
          const SizedBox(height: 20),
          Row(
            // crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }
}
