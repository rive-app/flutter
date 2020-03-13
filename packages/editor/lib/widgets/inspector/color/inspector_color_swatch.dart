import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_editor/widgets/inspector/color/color_popout.dart';
import 'package:rive_editor/widgets/inspector/color/color_preview.dart';
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
  InspectingColor _inspectingColor;

  @override
  void initState() {
    super.initState();
    _inspectingColor = InspectingColor(widget.shapePaints);
  }

  // TODO: might need to set a key so this recycles when we select another
  // component with the swatch in the same place.
  @override
  void dispose() {
    super.dispose();
    _popup?.close();
    _inspectingColor?.dispose();
    _inspectingColor = null;
  }

  @override
  void didUpdateWidget(InspectorColorSwatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shapePaints != widget.shapePaints) {
      _inspectingColor?.dispose();
      _inspectingColor = InspectingColor(widget.shapePaints);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _popup = InspectorPopout.popout(
          widget.inspectorContext,
          width: 206,
          builder: (context) => ColorPopout(inspecting: _inspectingColor),
        );
      },
      child: ValueListenableBuilder(
        valueListenable: _inspectingColor.preview,
        builder: (context, List<Color> colors, child) =>
            ColorPreview(colors: colors),
      ),
    );
  }
}
