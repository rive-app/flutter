import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/common/key_state_button.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/color_popout.dart';
import 'package:rive_editor/widgets/inspector/color/color_preview.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/popup/arrow_popup.dart';
import 'package:rive_widgets/frozen_value_listenable_builder.dart';

class TimelineColorSwatch extends StatefulWidget {
  final Component component;
  final int colorPropertyKey;
  final bool frozen;

  const TimelineColorSwatch({
    @required this.component,
    @required this.colorPropertyKey,
    this.frozen = false,
    Key key,
  }) : super(key: key);

  @override
  _TimelineColorSwatchState createState() => _TimelineColorSwatchState();
}

class _TimelineColorSwatchState extends State<TimelineColorSwatch> {
  ArrowPopup _arrowPopup;
  InspectingColor _inspectingColor;

  @override
  void initState() {
    super.initState();
    _updateInspectingColor();
  }

  @override
  void dispose() {
    super.dispose();
    _arrowPopup?.close();
    _inspectingColor?.dispose();
  }

  @override
  void didUpdateWidget(TimelineColorSwatch oldWidget) {
    if (oldWidget.colorPropertyKey != widget.colorPropertyKey ||
        oldWidget.component != widget.component) {
      _updateInspectingColor();
      // _arrowPopup?.markNeedsBuild();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _updateInspectingColor() {
    _inspectingColor?.dispose();
    _inspectingColor = InspectingColor.forSolidProperty(
        [widget.component], widget.colorPropertyKey);
    _arrowPopup?.popup?.markNeedsBuild();
  }

  void _setKeys(BuildContext context) {
    var editingAnimation =
        ActiveFile.find(context).editingAnimationManager.value;
    assert(editingAnimation != null);

    editingAnimation.keyComponents.add(KeyComponentsEvent(
        components: [widget.component], propertyKey: widget.colorPropertyKey));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTapDown: (_) {
            if (_arrowPopup != null) {
              // already open.
              return;
            }
            _arrowPopup = ArrowPopup.show(
              context,
              background: RiveTheme.of(context).colors.panelBackgroundDarkGrey,
              canCancelWithAction: true,
              borderRadius: BorderRadius.circular(10),
              showArrow: false,
              width: 206,
              builder: (popupContext) {
                var color = _inspectingColor;
                color.startEditing(ActiveFile.of(context));
                return ColorPopout(
                  inspecting: color,
                );
              },
              // autoClose: false,
              onClose: () {
                _inspectingColor.stopEditing();
                _arrowPopup = null;
              },
              shouldClose: () async {
                return _inspectingColor.shouldClickGuardClosePopup();
              },
            );
          },
          child: FrozenValueListenableBuilder(
            frozen: widget.frozen,
            valueListenable: _inspectingColor.preview,
            builder: (context, List<Color> colors, child) => ColorPreview(
              colors: colors,
            ),
          ),
        ),
        const SizedBox(width: 10),
        CorePropertyBuilder(
          frozen: widget.frozen,
          object: widget.component,
          propertyKey: widget.colorPropertyKey,
          builder: (context, int value, _) => KeyStateButton(
            keyState: RiveCoreContext.getKeyState(
                widget.component, widget.colorPropertyKey),
            setKey: () => _setKeys(context),
          ),
        ),
      ],
    );
  }
}
