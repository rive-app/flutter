import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/common/click_listener.dart';
import 'package:rive_editor/widgets/common/editor_text_field.dart';

typedef RenameCallback = void Function(String);

/// A Text widget that can be double clicked on to edit the text.
class Renamable extends StatefulWidget {
  final String name;
  final Color color;
  final Color editingColor;

  final RenameCallback onRename;
  const Renamable({
    Key key,
    this.name,
    this.color,
    this.editingColor,
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
      isListening: !_isEditing,
      onDoubleClick: () {
        if (widget.onRename == null) {
          // If the rename function isn't handled, don't start editing.
          return;
        }
        setState(() {
          _controller = TextEditingController(text: widget.name ?? '');
          _isEditing = true;
          _focusNode.requestFocus();
        });
      },
      child: Align(
        alignment: const Alignment(-1, 0),
        child: _isEditing
            ? RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  // Seems like the EditableText doesn't internally lose focus
                  // when esc is pressed, so we handle this manually here.
                  if (event.physicalKey == PhysicalKeyboardKey.escape) {
                    setState(() {
                      _isEditing = false;
                    });
                  }
                },
                child: EditorTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  color: widget.color,
                  editingColor: widget.editingColor,
                  onSubmitted: (text) {
                    widget.onRename?.call(text);
                  },

                  /*RepaintBoundary(
                    child: EditableText(
                      controller: _controller,
                      focusNode: _focusNode,
                      cursorColor: widget.editingColor ?? widget.color,
                      backgroundCursorColor:
                          widget.editingColor ?? widget.color,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.editingColor ?? widget.color,
                      ),
                      selectionControls: materialTextSelectionControls,
                      enableInteractiveSelection: true,
                      rendererIgnoresPointer: false,
                      showCursor: true,
                      selectionHeightStyle: BoxHeightStyle.tight,
                      selectionWidthStyle: BoxWidthStyle.tight,
                      keyboardType: TextInputType.multiline,
                      selectionColor:
                          RiveTheme.of(context).colors.textSelection,
                      onSubmitted: (text) {
                        widget.onRename?.call(text);
                      },
                    ),
                  ),*/
                ),
              )
            : Text(
                widget.name ?? '-',
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
