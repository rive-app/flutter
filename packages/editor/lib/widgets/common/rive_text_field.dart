import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class RiveTextField extends StatefulWidget {
  final bool enabled;
  final bool autofocus;
  final String initialValue;
  final String hintText;
  final String errorText;
  final double fontSize;
  final double errorFontSize;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final List<TextInputFormatter> formatters;
  final MainAxisAlignment errorAlignment;
  final GlobalKey<EditableTextState> editableKey;

  const RiveTextField({
    this.enabled = true,
    this.autofocus = false,
    this.initialValue,
    this.hintText,
    this.errorText,
    this.fontSize = 13,
    this.errorFontSize = 13,
    this.focusNode,
    this.onSubmit,
    this.onChanged,
    this.controller,
    this.formatters,
    this.errorAlignment = MainAxisAlignment.end,
    this.editableKey,
    Key key,
  }) : super(key: key);

  @override
  _RiveTextFieldState createState() => _RiveTextFieldState();
}

class _RiveTextFieldState extends State<RiveTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  FocusNode _focusNode;
  TextEditingController _textController;
  GlobalKey<EditableTextState> _editableTextKey;

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableTextKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  @override
  void initState() {
    _editableTextKey = widget.editableKey ?? GlobalKey<EditableTextState>();
    _textController = widget.controller ?? TextEditingController();
    _textController.text = widget.initialValue;
    _focusNode = FocusNode(canRequestFocus: true, skipTraversal: false);
    _focusNode.addListener(_getFocus);
    super.initState();
  }

  // On focus, select all text.
  void _getFocus() {
    if (!_focusNode.hasFocus) {
      return;
    }
    setState(() {
      editableTextKey.currentState?.requestKeyboard();
      _textController.selection = TextSelection(
          baseOffset: 0, extentOffset: _textController.text.length);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      // This State has instantiated FocusNode and should dispose it.
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      // This State has instantiated the controller and should dispose it.
      _textController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    var hasError = widget.errorText != null;

    return Column(
      children: [
        TextFormField(
          key: editableTextKey,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          onFieldSubmitted: widget.onSubmit,
          onChanged: widget.onChanged,
          inputFormatters: widget.formatters,
          controller: _textController,
          focusNode: _focusNode,
          textAlign: TextAlign.left,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: colors.commonDarkGrey,
          enableInteractiveSelection: false,
          showCursor: true,
          style:
              textStyles.fileGreyTextLarge.copyWith(fontSize: widget.fontSize),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: textStyles.textFieldInputHint
                .copyWith(fontSize: 13, height: 1.15),
            contentPadding: const EdgeInsets.only(bottom: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? colors.accentMagenta : colors.input,
                width: 2,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? colors.accentMagenta : colors.commonDarkGrey,
                width: 2,
              ),
            ),
          ),
        ),
        // If we have an error display the error label underneath.
        if (hasError)
          Row(
              mainAxisAlignment: widget.errorAlignment,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 2,
                    bottom: 3,
                    left: 5,
                    right: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentMagenta,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.zero,
                      bottom: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    widget.errorText,
                    style: textStyles.errorText,
                  ),
                ),
              ]),
      ],
    );
  }
}
