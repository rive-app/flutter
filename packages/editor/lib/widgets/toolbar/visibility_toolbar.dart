import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/nullable_listenable_builder.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/toolbar/check_popup_item.dart';

import 'package:rive_editor/widgets/toolbar/tool_popup_button.dart';

/// Visibility popup menu in the toolbar
class VisibilityPopupButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ToolPopupButton(
        width: 225,
        // Custom icon builder to show the zoom level
        // instead of a menu icon
        iconBuilder: (context, rive, isHovered) {
          return NullableListenableBuilder<ValueNotifier<int>>(
            listenable: rive.stage.value.zoomLevelNotifier,
            builder: (context, notifier, _) => Text(
              '${notifier.value}%',
              style: TextStyle(
                color: isHovered
                    ? RiveTheme.of(context).colors.toolbarButtonHover
                    : RiveTheme.of(context).colors.toolbarButton,
              ),
            ),
          );
        },
        makeItems: (rive) {
          return [
            PopupContextItem('Zoom',
                widgetBuilder: (context) => ValueNotifierTextField(
                      notifier: rive.stage.value.zoomLevelNotifier,
                    ),
                select: () {},
                dismissOnSelect: false),
            PopupContextItem('Resolution',
                widgetBuilder: (context) => ValueNotifierTextField(
                      notifier: rive.stage.value.resolutionNotifier,
                    ),
                select: () {},
                dismissOnSelect: false),
            PopupContextItem.separator(),
            CheckPopupItem(
              'Images',
              notifier: rive.stage.value.showImagesNotifier,
              isChecked: () => rive.stage.value.showImages,
              select: () =>
                  rive.stage.value.showImages = !rive.stage.value.showImages,
              dismissOnSelect: false,
            ),
            CheckPopupItem(
              'Image Contour',
              notifier: rive.stage.value.showContourNotifier,
              isChecked: () => rive.stage.value.showContour,
              select: () =>
                  rive.stage.value.showContour = !rive.stage.value.showContour,
              dismissOnSelect: false,
            ),
            CheckPopupItem(
              'Bones',
              notifier: rive.stage.value.showBonesNotifier,
              isChecked: () => rive.stage.value.showBones,
              select: () =>
                  rive.stage.value.showBones = !rive.stage.value.showBones,
              dismissOnSelect: false,
            ),
            CheckPopupItem(
              'Effects',
              notifier: rive.stage.value.showEffectsNotifier,
              isChecked: () => rive.stage.value.showEffects,
              select: () =>
                  rive.stage.value.showEffects = !rive.stage.value.showEffects,
              dismissOnSelect: false,
            ),
            CheckPopupItem(
              'Rulers',
              shortcut: ShortcutAction.toggleRulers,
              notifier: rive.stage.value.showRulersNotifier,
              isChecked: () => rive.stage.value.showRulers,
              select: () => rive.triggerAction(ShortcutAction.toggleRulers),
              dismissOnSelect: false,
            ),
            PopupContextItem(
              'Reset Rulers',
              padIcon: true,
              shortcut: ShortcutAction.resetRulers,
              select: () => rive.triggerAction(ShortcutAction.resetRulers),
            ),
            CheckPopupItem(
              'Grid',
              notifier: rive.stage.value.showGridNotifier,
              isChecked: () => rive.stage.value.showGrid,
              select: () =>
                  rive.stage.value.showGrid = !rive.stage.value.showGrid,
              dismissOnSelect: false,
            ),
            CheckPopupItem(
              'Axis',
              notifier: rive.stage.value.showAxisNotifier,
              isChecked: () => rive.stage.value.showAxis,
              select: () =>
                  rive.stage.value.showAxis = !rive.stage.value.showAxis,
              dismissOnSelect: false,
            ),
          ];
        });
  }
}

/// Text field for integer values.
/// Takes an int notifier into which the text field value will
/// be sent.
class ValueNotifierTextField extends StatefulWidget {
  const ValueNotifierTextField({
    @required this.notifier,
    Key key,
    this.hintText = '100%',
  }) : super(key: key);
  final ValueNotifier<int> notifier;
  final String hintText;

  @override
  _ValueNotifierTextFieldState createState() => _ValueNotifierTextFieldState();
}

class _ValueNotifierTextFieldState extends State<ValueNotifierTextField> {
  final _controller = TextEditingController();
  int value;

  void _validate() {
    // If the controller is empty, then the value is 0
    if (_controller.text.isEmpty) {
      value = 0;
      return;
    }

    try {
      value = int.parse(_controller.text);
    } on FormatException catch (_) {
      // Invalid value, ignore
      _controller.text = value.toString();
    }
    // Otherwise, save the value in the notifier
    widget.notifier.value = value;
  }

  @override
  void initState() {
    super.initState();
    value = widget.notifier.value;
    _controller.text = value.toString();
    _controller.addListener(_validate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      child: Center(
        child: TextField(
          controller: _controller,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    width: 2, color: RiveTheme.of(context).colors.separator)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: RiveTheme.of(context).colors.separatorActive)),
            hintText: widget.hintText,
            hintStyle: RiveTheme.of(context).textStyles.popupShortcutText,
          ),
          style: RiveTheme.of(context).textStyles.popupShortcutText,
        ),
      ),
    );
  }
}
