import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/common/click_listener.dart';
import 'package:rive_editor/widgets/common/editor_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

typedef RenameCallback = void Function(String);

/// A Text widget that can be double clicked on to edit the text.
class Renamable extends StatefulWidget {
  final String name;
  final Color color;
  final Color editingColor;
  final TextStyle style;

  final RenameCallback onRename;
  const Renamable({
    Key key,
    this.name,
    this.color,
    this.editingColor,
    this.onRename,
    this.style,
  }) : super(key: key);

  @override
  _RenamableState createState() => _RenamableState();
}

class _RenamableState extends State<Renamable> {
  bool _isEditing = false;
  TextEditingController _controller;
  final FocusNode _focusNode = FocusNode(canRequestFocus: true);
  bool _submitOnLoseFocus = true;

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
      if (_submitOnLoseFocus) {
        widget.onRename?.call(_controller.text);
      }
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
      onDoubleClick: (event) {
        if (widget.onRename == null) {
          // If the rename function isn't handled, don't start editing.
          return;
        }
        setState(() {
          _submitOnLoseFocus = true;
          _controller = TextEditingController(text: widget.name ?? '');
          _isEditing = true;
          _focusNode.requestFocus();
        });
      },
      child: Align(
        alignment: const Alignment(-1, 0),
        child: _isEditing
            ? RawKeyboardListener(
                focusNode: FocusNode(skipTraversal: true),
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
                  allowDrag: false,
                  controller: _controller,
                  focusNode: _focusNode,
                  color: widget.color ?? widget.style?.color,
                  style: widget.style ??
                      const TextStyle(
                        fontFamily: 'Roboto-Regular',
                        fontSize: 13,
                      ),
                  editingColor: widget.editingColor,
                  onSubmitted: (text) {
                    _submitOnLoseFocus = false;
                    widget.onRename?.call(text);

                    // Force focus back to the main context so that we can
                    // immediately undo this change if we want to by hitting
                    // ctrl/comamnd z.
                    RiveContext.of(context).debounceFocus();
                  },
                ),
              )
            : Text(
                widget.name ?? '-',
                overflow: TextOverflow.ellipsis,
                style: widget.style != null
                    ? widget.style.copyWith(color: widget.color)
                    : TextStyle(
                        fontFamily: 'Roboto-Regular',
                        fontSize: 13,
                        color: widget.color,
                      ),
              ),
      ),
    );
  }
}
