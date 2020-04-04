import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
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
  final InspectingColor inspectingColor;

  const InspectorColorSwatch({
    @required this.inspectingColor,
    @required this.inspectorContext,
    Key key,
  }) : super(key: key);

  @override
  _InspectorColorSwatchState createState() => _InspectorColorSwatchState();
}

class _InspectorColorSwatchState extends State<InspectorColorSwatch> {
  Popup _popup;

  @override
  void dispose() {
    super.dispose();
    _popup?.close();
  }

  @override
  void didUpdateWidget(InspectorColorSwatch oldWidget) {
    if (oldWidget.inspectingColor != widget.inspectingColor) {
      // Can't call markNeedsBuild on the popup during the build phase, so we
      // have to debounce here.
      // debounce(_rebuildPopup);
      _popup?.markNeedsBuild();
    }
    super.didUpdateWidget(oldWidget);
  }

  // void _rebuildPopup() => _popup?.markNeedsBuild();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (_popup != null) {
          // already open.
          return;
        }
        // var color = widget.inspectingColor;
        // color.startEditing(ActiveFile.of(context));
        // var editor = InspectingColorEditor(
        //   color: color,
        //   inspector: Inspector.of(context),
        //   file: ActiveFile.of(context),
        // );

        _popup = InspectorPopout.popout(
          widget.inspectorContext,
          width: 206,
          builder: (popupContext) {
            var color = widget.inspectingColor;
            color.startEditing(ActiveFile.of(context));
            return ColorPopout(
              inspecting: color,
            );
          },
          autoClose: false,
          onClose: () {
            _popup = null;
          },
        );
      },
      child: ValueListenableBuilder(
        valueListenable: widget.inspectingColor.preview,
        builder: (context, List<Color> colors, child) => ColorPreview(
          colors: colors,
        ),
      ),
    );
  }
}