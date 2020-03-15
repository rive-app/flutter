import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/editor_text_field.dart';
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

class InspectorTextField<T> extends StatefulWidget {
  final T value;
  final InputValueConverter<T> converter;

  const InspectorTextField({
    @required this.value,
    this.converter,
    Key key,
  }) : super(key: key);

  @override
  _InspectorTextFieldState<T> createState() => _InspectorTextFieldState<T>();
}

class _InspectorTextFieldState<T> extends State<InspectorTextField<T>> {
  final _ConvertingTextEditingController<T> _controller =
      _ConvertingTextEditingController<T>();
  final FocusNode _focusNode = FocusNode(canRequestFocus: true);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusChange);
    _controller.rawValue = widget.value;
    _controller.converter = widget.converter;
  }

  void _focusChange() {
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
    return EditorTextField(
      controller: _controller,
      focusNode: _focusNode,
      color: theme.colors.inspectorTextColor,
      editingColor: theme.colors.activeText,
    );
  }
}
