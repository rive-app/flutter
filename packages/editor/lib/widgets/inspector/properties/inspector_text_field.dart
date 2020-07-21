import 'package:core/debounce.dart';
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

  void reset() => _update();

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

  /// Callback invoked whenever a drop operation isn't possible because the
  /// displayed value isn't compatible with the value converter. This allows the
  /// controlling widget to do something with the drag amount if it wishes to.
  final void Function(double delta) dragFail;

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
    this.dragFail,
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
  bool _submitOnLoseFocus = true;
  String _stringValueOnFocus;

  @override
  void initState() {
    super.initState();
    _updateFocusNode();
    _lastValue = _controller.rawValue = widget.value;
    _controller.converter = widget.converter;
  }

  void _focusChange() {
    bool hasFocus = _focusNode.hasFocus;
    if (!hasFocus &&
        _submitOnLoseFocus &&
        _stringValueOnFocus != _controller.text) {
      // Before changing state, try to submit the value.
      widget.change?.call(
          _lastValue = widget.converter.fromEditingValue(_controller.text));
      if (widget.captureJournalEntry) {
        ActiveFile.find(context)?.core?.captureJournalEntry();
      }
      widget.completeChange?.call(_lastValue);
    }

    setState(() {
      _hasFocus = hasFocus;
    });
    if (!hasFocus) {
      return;
    }
    _submitOnLoseFocus = true;
    // Select all.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    _stringValueOnFocus = _controller.text;
  }

  @override
  void dispose() {
    cancelDebounce(_returnFocusToEditor);
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

  bool get isDragging => _startDragValue != null;

  @override
  void didUpdateWidget(InspectorTextField<T> oldWidget) {
    if (oldWidget.focusNode != widget.focusNode) {
      _updateFocusNode();
    }
    if (isDragging) {
      // If we're actively dragging, don't change our accumulating _lastValue
      // from under our (or the controller's) feet, let it keep updating the
      // drag until it completes which will inherently change the value and
      // re-trigger a didUpdateWidget.
      super.didUpdateWidget(oldWidget);
      return;
    }
    _syncWithWidgetValue();
    super.didUpdateWidget(oldWidget);
  }

  void _syncWithWidgetValue() {
    _lastValue = _controller.rawValue = widget.value;
    _controller.converter = widget.converter;
  }

  void _completeChange({bool debounceFocus = false}) {
    _startDragValue = null;

    if (widget.captureJournalEntry) {
      ActiveFile.find(context)?.core?.captureJournalEntry();
    }
    widget.completeChange?.call(_lastValue);
    _syncWithWidgetValue();

    // When this gets called via onSubmitted the enter event will propagate to
    // the editor's focus node. We want to avoid that as it'll cause the submit
    // action and an editor bound 'enter' action to trigger (like edit
    // vertices). So we debounce it to allow the main editor focus node to
    // ignore the enter press.
    if (debounceFocus) {
      debounce(_returnFocusToEditor);
    } else {
      // Force focus back to the main context so that we can immediately
      // undo this change if we want to by hitting ctrl/command z.
      _returnFocusToEditor();
    }
  }

  void _returnFocusToEditor() {
    RiveContext.find(context).focus();
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
                focusNode: FocusNode(skipTraversal: true),
                onKey: (event) {
                  if (event is RawKeyDownEvent) {
                    // lose focus if escape is hit
                    if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
                      _controller.reset();
                      _submitOnLoseFocus = false;
                      _focusNode.unfocus();
                      debounce(_returnFocusToEditor);
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
                  drag: (amount) {
                    if (_lastValue == null) {
                      // If an error occurs when attempting to convert drag
                      // values, just bubble up that the drag failed and how
                      // much we tried to drag by. This can occur in our system
                      // when dragging multiple values that are displaying an
                      // empty state that the converter cannot deal with. It's
                      // up to the controlling widget to process the drag
                      // individually for each object. See #1020
                      widget.dragFail?.call(amount);
                    } else {
                      widget.change(_lastValue =
                          widget.converter.drag(_lastValue, amount));
                      _controller.rawValue = _lastValue;
                    }
                  },
                  completeDrag: _completeChange,
                  onSubmitted: (string) {
                    _submitOnLoseFocus = false;
                    widget.change?.call(
                        _lastValue = widget.converter.fromEditingValue(string));
                    _completeChange(debounceFocus: true);
                  },
                ),
              ),
      ),
    );
  }
}
