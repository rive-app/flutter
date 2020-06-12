import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/rive_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class LabeledTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final String errorText;
  final String initialValue;
  final bool enabled;
  final bool autofocus;
  final int maxCharacters;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  const LabeledTextField({
    @required this.label,
    this.hintText,
    this.errorText,
    this.initialValue,
    this.enabled = true,
    this.autofocus = false,
    this.maxCharacters,
    this.onSubmit,
    this.onChanged,
    this.controller,
    Key key,
  }) : super(key: key);

  @override
  _LabeledTextFieldState createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  final _focusNode = FocusNode(canRequestFocus: true, skipTraversal: false);

  GlobalKey<EditableTextState> _editableTextKey;

  @override
  void initState() {
    _editableTextKey = GlobalKey<EditableTextState>();
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = RiveTheme.of(context).textStyles;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      // onDoubleTap: _focusNode.requestFocus,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.label,
              style: textStyles.hierarchyTabHovered
                  .copyWith(fontSize: 13, height: 1.15)),
          const SizedBox(height: 10),
          RiveTextField(
            editableKey: _editableTextKey,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            initialValue: widget.initialValue,
            hintText: widget.hintText,
            errorText: widget.errorText,
            controller: widget.controller,
            onChanged: widget.onChanged,
            onSubmit: widget.onSubmit,
            focusNode: _focusNode,
            maxCharacters: widget.maxCharacters,
          ),
        ],
      ),
    );
  }
}
