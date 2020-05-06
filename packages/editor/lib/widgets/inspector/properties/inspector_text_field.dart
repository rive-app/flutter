import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final void Function(T value) completeChange;

  /// Placeholder text shown when disabled.
  final String disabledText;

  final FocusNode focusNode;

  final bool captureJournalEntry;

  /// Color for the underline when it's not focused.
  final Color underlineColor;

  /// Color for the underline when this textfield has focus.
  final Color focusedUnderlineColor;

  /// Trailing widget to inject after the text editor.
  final Widget trailing;

  const InspectorTextField({
    @required this.value,
    @required this.converter,
    this.disabledText = '',
    this.focusNode,
    this.change,
    this.completeChange,
    this.captureJournalEntry = true,
    this.underlineColor,
    this.focusedUnderlineColor,
    this.trailing,
    Key key,
  }) : super(key: key);

  @override
  _InspectorTextFieldState<T> createState() => _InspectorTextFieldState<T>();
}

class _InspectorTextFieldState<T> extends State<InspectorTextField<T>> {
  final _ConvertingTextEditingController<T> _controller =
      _ConvertingTextEditingController<T>();
  FocusNode _focusNode;
  bool _hasFocus = false;
  bool _ownsFocusNode = false;
  T _lastValue;
  T _startDragValue;

  @override
  void initState() {
    super.initState();
    _updateFocusNode();
    _lastValue = _controller.rawValue = widget.value;
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
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _updateFocusNode() {
    if (_ownsFocusNode) {
      _focusNode?.dispose();
    }
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ??
        FocusNode(canRequestFocus: true, skipTraversal: false);
    _focusNode.addListener(_focusChange);
  }

  @override
  void didUpdateWidget(InspectorTextField<T> oldWidget) {
    if (oldWidget.focusNode != widget.focusNode) {
      _updateFocusNode();
    }
    _lastValue = _controller.rawValue = widget.value;
    _controller.converter = widget.converter;
    super.didUpdateWidget(oldWidget);
  }

  void _completeChange() {
    if (widget.captureJournalEntry) {
      ActiveFile.find(context)?.core?.captureJournalEntry();
    }
    // Force focus back to the main context so that we can immediately
    // undo this change if we want to by hitting ctrl/command z.
    RiveContext.find(context).focus();
    widget.completeChange?.call(_lastValue);
  }

  Widget _addTrailingWidget(BuildContext context, Widget child) {
    if (widget.trailing == null) {
      return child;
    }
    return Row(
      children: [
        Expanded(child: child),
        widget.trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Underline(
      color: _hasFocus
          ? widget.focusedUnderlineColor ?? theme.colors.separatorActive
          : widget.underlineColor ?? theme.colors.separator,
      child: _addTrailingWidget(
        context,
        widget.change == null
            ? Text(
                widget.disabledText,
                overflow: TextOverflow.clip,
                maxLines: 1,
                style: theme.textStyles.inspectorPropertyLabel,
              )
            : RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  if (event is RawKeyDownEvent) {
                    // lose focus if escape is hit
                    if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
                      _focusNode.unfocus();
                    }
                  }
                },
                child: EditorTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  color: theme.colors.inspectorTextColor,
                  editingColor: theme.colors.activeText,
                  allowDrag: widget.converter.allowDrag,
                  startDrag: () => _startDragValue = _lastValue,
                  cancelDrag: () {
                    widget.change?.call(_lastValue = _startDragValue);
                    _completeChange();
                  },
                  drag: (amount) => widget.change(
                      _lastValue = widget.converter.drag(widget.value, amount)),
                  completeDrag: _completeChange,
                  onSubmitted: (string) {
                    widget.change?.call(
                        _lastValue = widget.converter.fromEditingValue(string));
                    _completeChange();
                  },
                ),
              ),
      ),
    );
  }
}
