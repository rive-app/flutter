import 'dart:ui';

import 'package:core/key_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/key_state_button.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';

/// A text field that manipulates core properties.
///
/// The [propertyKey] is hander over to [CorePropertiesBuilder] to extract the
/// associated field data to be displayed within this text field.
class CoreTextField<T> extends StatelessWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final InputValueConverter<T> converter;
  final void Function(T value) change;
  final FocusNode focusNode;

  /// Color for the underline when it's not focused.
  final Color underlineColor;

  /// Color for the underline when this textfield has focus.
  final Color focusedUnderlineColor;

  const CoreTextField({
    @required this.objects,
    @required this.propertyKey,
    this.converter,
    this.change,
    this.focusNode,
    this.underlineColor,
    this.focusedUnderlineColor,
    Key key,
  }) : super(key: key);

  Widget _determineEditorMode(
      BuildContext context, Widget Function(EditorMode) build) {
    bool isAnimated = RiveCoreContext.animates(propertyKey);
    if (!isAnimated) {
      return build(null);
    }

    var activeFile = ActiveFile.of(context);
    if (activeFile == null) {
      return build(null);
    }

    return ValueListenableBuilder(
      valueListenable: activeFile.mode,
      builder: (context, EditorMode mode, _) => build(mode),
    );
  }

  KeyState _computeKeyState() {
    if (objects.isEmpty) {
      return null;
    }
    var itr = objects.iterator;
    itr.moveNext();

    var value = RiveCoreContext.getKeyState(itr.current, propertyKey);

    while (itr.moveNext()) {
      if (value != RiveCoreContext.getKeyState(itr.current, propertyKey)) {
        return null;
      }
    }
    return value;
  }

  void _setKeys(BuildContext context) {
    // set key
    var components = objects.cast<Component>();
    var editingAnimation =
        ActiveFile.find(context).editingAnimationManager.value;
    assert(components != null);
    assert(editingAnimation != null);

    editingAnimation.keyComponents.add(
        KeyComponentsEvent(components: components, propertyKey: propertyKey));
  }

  @override
  Widget build(BuildContext context) {
    return _determineEditorMode(
      context,
      (mode) => CorePropertiesBuilder(
        objects: objects,
        propertyKey: propertyKey,
        builder: (context, T value, _) => InspectorTextField(
          value: value,
          focusNode: focusNode,
          converter: converter,
          underlineColor: underlineColor,
          focusedUnderlineColor: focusedUnderlineColor,
          trailing: mode == EditorMode.animate
              ? KeyStateButton(
                  keyState: _computeKeyState(),
                  setKey: () => _setKeys(context),
                )
              : null,
          change: (T value) {
            for (final object in objects) {
              object.context.setObjectProperty(object, propertyKey, value);
            }
            change?.call(value);
          },
        ),
      ),
    );
  }
}
