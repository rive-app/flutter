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
          valueListenable: rive.stage.zoomLevelNotifier,
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
      makeItems: (file) {
        // Use keys for the input widgets so they don't recycle.
        var zoomKey = GlobalKey();
        var resKey = GlobalKey();
        return [
          PopupContextItem(
            'Zoom',
            child: ValueNotifierTextField(
              key: zoomKey,
              notifier: file.stage.zoomLevelNotifier,
              converter: ZoomInputConverter.instance,
              change: (double value) => file.stage.zoomLevel = value,
            ),
            select: () {},
            dismissOnSelect: false,
          ),
          PopupContextItem('Resolution',
              child: ValueNotifierTextField(
                key: resKey,
                notifier: file.stage.resolutionNotifier,
                converter: ZoomInputConverter.instance,
              ),
              select: () {},
              dismissOnSelect: false),
          PopupContextItem.separator(),
          CheckPopupItem(
            'Images',
            notifier: file.stage.showImagesNotifier,
            isChecked: () => file.stage.showImages,
            select: () => file.stage.showImages = !file.stage.showImages,
            dismissOnSelect: false,
          ),
          CheckPopupItem(
            'Image Contour',
            notifier: file.stage.showContourNotifier,
            isChecked: () => file.stage.showContour,
            select: () => file.stage.showContour = !file.stage.showContour,
            dismissOnSelect: false,
          ),
          CheckPopupItem(
            'Bones',
            notifier: file.stage.showBonesNotifier,
            isChecked: () => file.stage.showBones,
            select: () => file.stage.showBones = !file.stage.showBones,
            dismissOnSelect: false,
          ),
          CheckPopupItem(
            'Effects',
            notifier: file.stage.showEffectsNotifier,
            isChecked: () => file.stage.showEffects,
            select: () => file.stage.showEffects = !file.stage.showEffects,
            dismissOnSelect: false,
          ),
          CheckPopupItem(
            'Rulers',
            shortcut: ShortcutAction.toggleRulers,
            notifier: file.stage.showRulersNotifier,
            isChecked: () => file.stage.showRulers,
            select: () => file.rive.triggerAction(ShortcutAction.toggleRulers),
            dismissOnSelect: false,
          ),
          PopupContextItem(
            'Reset Rulers',
            padIcon: true,
            shortcut: ShortcutAction.resetRulers,
            select: () => file.rive.triggerAction(ShortcutAction.resetRulers),
          ),
          CheckPopupItem(
            'Grid',
            notifier: file.stage.showGridNotifier,
            isChecked: () => file.stage.showGrid,
            select: () => file.stage.showGrid = !file.stage.showGrid,
            dismissOnSelect: false,
          ),
          CheckPopupItem(
            'Axis',
            notifier: file.stage.showAxisNotifier,
            isChecked: () => file.stage.showAxis,
            select: () => file.stage.showAxis = !file.stage.showAxis,
            dismissOnSelect: false,
          ),
        ];
      },
    );
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
