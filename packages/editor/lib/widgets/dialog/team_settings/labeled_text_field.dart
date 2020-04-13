import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class LabeledTextField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String label;
  final String hint;
  final String initialValue;

  const LabeledTextField({
    @required this.label,
    this.hint,
    this.onChanged,
    this.initialValue,
    Key key,
  }) : super(key: key);

  @override
  _LabeledTextFieldState createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final _focusNode = FocusNode(canRequestFocus: true, skipTraversal: false);
  final _textController = TextEditingController();

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  @override
  void initState() {
    _textController.text = widget.initialValue;
    _focusNode.addListener(_getFocus);
    super.initState();
  }

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
    _focusNode.dispose(); // Also removes listeners.
    _textController.dispose();
    super.dispose();
  }

  final TextSelectionControls selectionControls = materialTextSelectionControls;
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;

    return GestureDetector(
      onTap: _focusNode.requestFocus,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.label,
              style: textStyles.hierarchyTabHovered
                  .copyWith(fontSize: 13, height: 1.15)),
          const SizedBox(height: 11),
          TextFormField(
              key: editableTextKey,
              onChanged: widget.onChanged,
              cursorColor: colors.commonDarkGrey,
              controller: _textController,
              focusNode: _focusNode,
              enableInteractiveSelection: false,
              showCursor: true,
              textAlign: TextAlign.left,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hint,
                hintStyle: textStyles.textFieldInputHint
                    .copyWith(fontSize: 13, height: 1.15),
                contentPadding: const EdgeInsets.only(bottom: 2),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.input, width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: colors.commonDarkGrey, width: 2)),
              ),
              style: textStyles.fileGreyTextLarge
                  .copyWith(fontSize: 13, letterSpacing: 0)),
        ],
      ),
    );
  }
}
