import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/editor_text_field.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class _ConvertingTextEditingController<T> extends TextEditingController {
  T _rawValue;
  T get rawValue => _rawValue;
  set rawValue(T value) {
    if (_rawValue == value) {
      return;
    }
    _rawValue = value;
    _update();
  }

  InputValueConverter<T> _converter;
  InputValueConverter<T> get converter => _converter;
  set converter(InputValueConverter<T> value) {
    if (_converter == value) {
      return;
    }
    _converter = value;
    _update();
  }

  void _update() {
    text = _rawValue == null
        ? ''
        : _converter == null
            ? _rawValue.toString()
            : _converter.toEditingValue(_rawValue);
  }

  bool get isEditing => value.selection.isValid;

  String get displayValue => _rawValue == null
      ? '-'
      : _converter == null
          ? _rawValue.toString()
          : _converter.toDisplayValue(_rawValue);

  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    String displayText = isEditing ? text : displayValue;
    // return super.buildTextSpan(style: style, withComposing: withComposing);

    if (!value.composing.isValid || !withComposing) {
      return TextSpan(style: style, text: displayText);
    }
    final TextStyle composingStyle = style.merge(
      const TextStyle(decoration: TextDecoration.underline),
    );
    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(text: value.composing.textBefore(displayText)),
        TextSpan(
          style: composingStyle,
          text: value.composing.textInside(displayText),
        ),
        TextSpan(text: value.composing.textAfter(displayText)),
      ],
    );
  }
}

/// A TextField whose value can be of any type [T]. It automatically hanldes
/// changes to the value based on the provided converter.
class InspectorTextField<T> extends StatefulWidget {
  /// The raw value to be displayed and edited.
  final T value;

  /// The converter which interprets the provided value as an editable string
  /// and is also able to convert it back to the raw value of type [T].
  final InputValueConverter<T> converter;

  /// Callback invoked whenever the value changes. Can be called before the
  /// editing operation is fully complete in order to allow the user to preview
  /// the changes as they are made.
  final void Function(T value) change;

  /// Callback for when the editing operation is fully complete. This is when
  /// you want to save the changed value (or track the change for undo/redo).
  final void Function() completeChange;

  const InspectorTextField({
    @required this.value,
    @required this.converter,
    this.change,
    this.completeChange,
    Key key,
  }) : super(key: key);

  @override
  _InspectorTextFieldState<T> createState() => _InspectorTextFieldState<T>();
}

class _InspectorTextFieldState<T> extends State<InspectorTextField<T>> {
  final _ConvertingTextEditingController<T> _controller =
      _ConvertingTextEditingController<T>();
  final FocusNode _focusNode = FocusNode(canRequestFocus: true);
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusChange);
    _controller.rawValue = widget.value;
    _controller.converter = widget.converter;
  }

  void _focusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
    if (!_focusNode.hasFocus) {
      return;
    }
    // Select all.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InspectorTextField<T> oldWidget) {
    _controller.rawValue = widget.value;
    _controller.converter = widget.converter;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Underline(
      color: _hasFocus ? theme.colors.separatorActive : theme.colors.separator,
      child: EditorTextField(
        controller: _controller,
        focusNode: _focusNode,
        color: theme.colors.inspectorTextColor,
        editingColor: theme.colors.activeText,
        onSubmitted: (string) {
          widget.change?.call(widget.converter.fromEditingValue(string));
          widget.completeChange?.call();
        },
      ),
    );
  }
}
