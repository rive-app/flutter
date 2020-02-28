import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class RiveTextFormField extends StatefulWidget {
  const RiveTextFormField({
    @required this.hintText,
    @required this.initialValue,
    this.onComplete,
    this.onChanged,
    this.edgeInsets = EdgeInsets.zero,
    Key key,
  }) : super(key: key);

  final String hintText;
  final String initialValue;
  final ValueChanged<String> onComplete, onChanged;
  final EdgeInsets edgeInsets;

  @override
  _RiveTextFormFieldState createState() => _RiveTextFormFieldState();
}

class _RiveTextFormFieldState extends State<RiveTextFormField> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.initialValue;
    super.initState();
  }

  @override
  void didUpdateWidget(RiveTextFormField oldWidget) {
    if (oldWidget.initialValue != widget.initialValue) {
      if (widget.initialValue != _controller.text) {
        _controller.text = widget.initialValue;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        textAlignVertical: TextAlignVertical.top,
        scrollPadding: EdgeInsets.zero,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: widget.edgeInsets,
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  width: 1, color: RiveTheme.of(context).colors.separator)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  width: 1,
                  color: RiveTheme.of(context).colors.separatorActive)),
          hintText: widget.hintText,
          hintStyle: RiveTheme.of(context).textStyles.inspectorPropertyValue,
        ),
        style: RiveTheme.of(context).textStyles.inspectorPropertyValue,
        onChanged: widget.onChanged,
        onSaved: widget.onComplete,
        onEditingComplete: () {
          _formKey.currentState.save();
        },
      ),
    );
  }
}
