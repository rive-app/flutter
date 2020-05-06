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
class CoreTextField<T> extends StatefulWidget {
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

  @override
  _CoreTextFieldState<T> createState() => _CoreTextFieldState<T>();
}

class _CoreTextFieldState<T> extends State<CoreTextField<T>> {
  Widget _determineEditorMode(
      BuildContext context, Widget Function(EditorMode) build) {
    bool isAnimated = RiveCoreContext.animates(widget.propertyKey);
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
    var objects = widget.objects;
    if (objects.isEmpty) {
      return null;
    }
    var propertyKey = widget.propertyKey;
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

  void _setKeys() {
    // set key
    var components = widget.objects.cast<Component>();
    assert(components != null);
    assert(EditingAnimationProvider.find(context) != null);

    EditingAnimationProvider.find(context).keyComponents.add(KeyComponentsEvent(
        components: components, propertyKey: widget.propertyKey));
  }

  @override
  Widget build(BuildContext context) {
    return _determineEditorMode(
      context,
      (mode) => CorePropertiesBuilder(
        objects: widget.objects,
        propertyKey: widget.propertyKey,
        builder: (context, T value, _) => InspectorTextField(
          value: value,
          focusNode: widget.focusNode,
          converter: widget.converter,
          underlineColor: widget.underlineColor,
          focusedUnderlineColor: widget.focusedUnderlineColor,
          trailing: mode == EditorMode.animate
              ? KeyStateWidget(
                  keyState: _computeKeyState(),
                  setKey: _setKeys,
                )
              : null,
          change: (T value) {
            for (final object in widget.objects) {
              object.context
                  .setObjectProperty(object, widget.propertyKey, value);
            }
            widget.change?.call(value);
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

class KeyStateRenderBox extends RenderBox with KeyPathMaker {
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
    makeKeyPath(_theme, Offset(pos, pos));
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
