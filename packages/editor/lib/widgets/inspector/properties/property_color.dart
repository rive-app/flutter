import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/color/inspector_color_swatch.dart';

/// Inspector for a core property that represents color.
class PropertyColor extends StatefulWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final String name;

  const PropertyColor({
    @required this.objects,
    @required this.propertyKey,
    this.name,
    Key key,
  }) : super(key: key);

  @override
  _PropertyColorState createState() => _PropertyColorState();
}

class _PropertyColorState extends State<PropertyColor> {
  InspectingColor _inspectingColor;
  @override
  void initState() {
    _inspectingColor =
        InspectingColor.forSolidProperty(widget.objects, widget.propertyKey);
    super.initState();
  }

  @override
  void didUpdateWidget(PropertyColor oldWidget) {
    _inspectingColor?.dispose();
    _inspectingColor =
        InspectingColor.forSolidProperty(widget.objects, widget.propertyKey);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var textStyles = theme.textStyles;
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 7,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.name,
              style: textStyles.inspectorPropertyLabel,
            ),
          ),
          const SizedBox(width: 20),
          InspectorColorSwatch(
            inspectorContext: context,
            inspectingColor: _inspectingColor,
          ),
        ],
      ),
    );
  }
}
