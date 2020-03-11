import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_editor/widgets/inspector/color/color_popout.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout.dart';
import 'package:rive_editor/widgets/popup/base_popup.dart';

/// A color swatch button that shows the current color value (solid or gradient)
/// and also triggers a [ColorPopout] when pressed.
///
/// ![](https://assets.rvcd.in/inspector/color/color_swatch.png)
class InspectorColorSwatch extends StatefulWidget {
  final BuildContext inspectorContext;
  final Iterable<ShapePaint> shapePaints;

  const InspectorColorSwatch({
    Key key,
    this.inspectorContext,
    this.shapePaints,
  }) : super(key: key);

  @override
  _InspectorColorSwatchState createState() => _InspectorColorSwatchState();
}

class _InspectorColorSwatchState extends State<InspectorColorSwatch> {
  Popup _popup;

  // TODO: might need to set a key so this recycles when we select another
  // component with the swatch in the same place.
  @override
  void dispose() {
    super.dispose();
    _popup?.close();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        var inspecting = InspectingColor(widget.shapePaints);
        _popup = InspectorPopout.popout(
          widget.inspectorContext,
          width: 206,
          builder: (context) => ColorPopout(inspecting: inspecting),
        );
      },
      child: Container(
        width: 30,
        height: 20,
        decoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: Colors.white,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
