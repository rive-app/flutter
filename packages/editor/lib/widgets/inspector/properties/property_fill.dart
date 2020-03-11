import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inspector/color/inspector_color_swatch.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_component.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';

class PropertyFill extends StatelessWidget {
  final Iterable<Fill> fills;

  const PropertyFill({
    @required this.fills,
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
          shapePaints: fills,
        ),
      ),
      isVisiblePropertyKey: ShapePaintBase.isVisiblePropertyKey,
    );
  }
}
