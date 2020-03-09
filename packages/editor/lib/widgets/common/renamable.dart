import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'click_listener.dart';

typedef RenameCallback = void Function(String);

/// A Text widget that can be double clicked on to edit the text.
class Renamable extends StatefulWidget {
  final String name;
  final Color color;
  final RenameCallback onRename;
  const Renamable({
    Key key,
    this.name,
    this.color,
    this.onRename,
  }) : super(key: key);

  @override
  _RenamableState createState() => _RenamableState();
}

class _RenamableState extends State<Renamable> {
  bool _isEditing = false;
  TextEditingController _controller;
  final FocusNode _focusNode = FocusNode(canRequestFocus: true);

  @override
  void initState() {
    _focusNode.addListener(_focusChange);
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusChange);
    super.dispose();
  }

  void _focusChange() {
    if (!_focusNode.hasPrimaryFocus) {
      setState(() {
        _isEditing = false;
      });
    } else {
      _controller?.selection =
          TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClickListener(
      onDoubleClick: () {
        setState(() {
          _controller = TextEditingController(text: widget.name);
          _isEditing = true;
          _focusNode.requestFocus();
        });
      },
      child: Align(
        alignment: const Alignment(-1, 0),
        // color:Colors.green,
        child: _isEditing
            ? RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  // Seems like the TextField doesn't internally lose focus when
                  // esc is pressed, so we handle this manually here.
                  if (event.physicalKey == PhysicalKeyboardKey.escape) {
                    setState(() {
                      _isEditing = false;
                    });
                  }
                },
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSubmitted: (text) {
                    widget.onRename?.call(text);
                  },
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.color,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    isDense: true,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    border: InputBorder.none,
                    filled: false,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              )
            : Text(
                widget.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.color,
                ),
              ),
      ),
    );
  }
}
