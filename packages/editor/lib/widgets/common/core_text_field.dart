import 'package:core/key_state.dart';
import 'package:cursor/propagating_listener.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/animation/key_path_maker.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
import 'package:rive_editor/widgets/theme.dart';

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
    assert(components != null);
    assert(EditingAnimationProvider.find(context) != null);

    EditingAnimationProvider.find(context).keyComponents.add(
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
              ? KeyStateWidget(
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

class KeyStateWidget extends StatelessWidget {
  final KeyState keyState;
  final void Function() setKey;

  const KeyStateWidget({
    Key key,
    this.keyState,
    this.setKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropagatingListener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (details) => setKey(),
      child: KeyStateRenderer(
        keyState: keyState,
        theme: RiveTheme.of(context),
      ),
    );
  }
}

@immutable
class KeyStateRenderer extends LeafRenderObjectWidget {
  final KeyState keyState;
  final RiveThemeData theme;

  const KeyStateRenderer({
    @required this.keyState,
    @required this.theme,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    return KeyStateRenderBox()
      ..keyState = keyState
      ..theme = theme;
  }

  @override
  void updateRenderObject(
      BuildContext context, KeyStateRenderBox renderObject) {
    renderObject
      ..keyState = keyState
      ..theme = theme;
  }
}

class KeyStateRenderBox extends RenderBox {
  final Path keyPath = Path();
  final Paint none = Paint()..style = PaintingStyle.stroke;
  final Paint keyframe = Paint();
  final Paint interpolated = Paint()..style = PaintingStyle.stroke;

  RiveThemeData _theme;
  RiveThemeData get theme => _theme;
  set theme(RiveThemeData value) {
    if (value == _theme) {
      return;
    }
    _theme = value;
    markNeedsPaint();

    var pos = theme.dimensions.keyHalfBounds.roundToDouble();
    makeKeyPath(keyPath, _theme, Offset(pos, pos));
    none.color = _theme.colors.keyStateEmpty;
    keyframe.color = _theme.colors.key;
    interpolated.color = _theme.colors.key;
  }

  KeyState _keyState;
  KeyState get keyState => _keyState;
  set keyState(KeyState value) {
    if (value == _keyState) {
      return;
    }
    _keyState = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = Size(
        theme.dimensions.keyHalfBounds * 2, theme.dimensions.keyHalfBounds * 2);
  }

  @override
  bool get sizedByParent => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    Paint paint;
    switch (_keyState) {
      case KeyState.none:
        paint = none;
        break;
      case KeyState.keyframe:
        paint = keyframe;
        break;
      case KeyState.interpolated:
        paint = interpolated;
        break;
    }
    if (paint == null) {
      return;
    }
    // canvas.drawRect(offset & size, paint);
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPath(keyPath, paint);
    canvas.translate(-offset.dx, -offset.dy);
  }
}
