import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/zoom_input_converter.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
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
          var theme = RiveTheme.of(context);
          return ValueListenableBuilder<double>(
            valueListenable: rive.stage.value.zoomLevelNotifier,
            builder: (context, value, _) => SizedBox(
              width: 32,
              child: Text(
                ZoomInputConverter.instance.toDisplayValue(value),
                textAlign: TextAlign.right,
                style: theme.textStyles.basic.copyWith(
                  color: isHovered
                      ? theme.colors.toolbarButtonHover
                      : theme.colors.toolbarButton,
                ),
              ),
            ),
          );
        },
        makeItems: (rive) {
          // Use keys for the input widgets so they don't recycle.
          var zoomKey = GlobalKey();
          var resKey = GlobalKey();
          return [
            PopupContextItem(
              'Zoom',
              child: ValueNotifierTextField(
                key: zoomKey,
                notifier: rive.stage.value.zoomLevelNotifier,
                converter: ZoomInputConverter.instance,
                change: (double value) => rive.stage.value.zoomLevel = value,
              ),
              select: () {},
              dismissOnSelect: false,
            ),
            PopupContextItem('Resolution',
                child: ValueNotifierTextField(
                  key: resKey,
                  notifier: rive.stage.value.resolutionNotifier,
                  converter: ZoomInputConverter.instance,
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

/// Text field for T values. Takes a T notifier into which the text field value
/// will be sent.
class ValueNotifierTextField<T> extends StatelessWidget {
  const ValueNotifierTextField({
    @required this.notifier,
    @required this.converter,
    @required this.change,
    Key key,
  }) : super(key: key);
  final ValueNotifier<T> notifier;
  final InputValueConverter<T> converter;
  final void Function(T value) change;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      child: ValueListenableBuilder<T>(
        valueListenable: notifier,
        builder: (context, value, _) => InspectorTextField<T>(
          value: value,
          change: change,
          converter: converter,
        ),
      ),
    );
  }
}
