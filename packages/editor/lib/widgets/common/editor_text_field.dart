import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/cursor_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:cursor/propagating_listener.dart';

/// A text field that allows editing generic value types using generic value
/// converters.
class EditorTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color color;
  final Color editingColor;
  final ValueChanged<String> onSubmitted;
  final bool allowDrag;
  final void Function(double) drag;
  final void Function() completeDrag;

  const EditorTextField({
    @required this.controller,
    this.focusNode,
    this.color,
    this.editingColor,
    this.onSubmitted,
    this.allowDrag = true,
    this.drag,
    this.completeDrag,
    Key key,
  }) : super(key: key);

  @override
  _EditorTextFieldState createState() => _EditorTextFieldState();
}

class _EditorTextFieldState extends State<EditorTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  _EditorFieldGestureBuilder _selectionGestureDetectorBuilder;
  final TextSelectionControls selectionControls = materialTextSelectionControls;

  void _requestKeyboard() => editableTextKey.currentState?.requestKeyboard();

  @override
  void initState() {
    widget.focusNode?.addListener(_focusChanged);
    _selectionGestureDetectorBuilder = _EditorFieldGestureBuilder(state: this);
    super.initState();
  }

  @override
  void didUpdateWidget(EditorTextField oldWidget) {
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_focusChanged);
      widget.focusNode?.addListener(_focusChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_focusChanged);
    super.dispose();
  }

  void _focusChanged() {
    if (widget.focusNode.hasFocus) {
      CursorIcon.reset(context);
    }
  }

  bool get _isFocused => widget.focusNode.hasFocus;

  Widget _handleVerticalDrag(Widget child) {
    var rive = RiveContext.of(context);
    return _isFocused || !widget.allowDrag
        ? child
        : MouseRegion(
            onEnter: (data) {
              if (!rive.isDragging) {
                CursorIcon.show(context, 'cursor-resize-vertical');
              }
            },
            onExit: (data) {
              CursorIcon.reset(context);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (data) {
                rive.startDragOperation();
              },
              onVerticalDragUpdate: (data) {
                widget.drag?.call(data.delta.dy);
              },
              onVerticalDragEnd: (details) {
                widget.completeDrag?.call();
                rive.endDragOperation();
              },
              onTapUp: (data) {
                widget.focusNode.requestFocus();
              },
              child: IgnorePointer(child: child),
            ),
          );
  }

  Widget _listen(Widget child) {
    return PropagatingListener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // We only want to stop propagation when we know the
        // editable text will handle this click, which happens to be
        // the case if we're editing.
        event.stopPropagation();
      },
      child: _handleVerticalDrag(
        _selectionGestureDetectorBuilder.buildGestureDetector(
          behavior: HitTestBehavior.translucent,
          child: GestureDetector(
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _listen(
      RepaintBoundary(
        child: EditableText(
          key: editableTextKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          cursorColor: widget.editingColor ?? widget.color,
          backgroundCursorColor: widget.editingColor ?? widget.color,
          style: TextStyle(
            fontSize: 13,
            color: widget.editingColor ?? widget.color,
          ),
          selectionControls: selectionControls,
          enableInteractiveSelection: false,
          rendererIgnoresPointer: true,
          showCursor: true,
          selectionHeightStyle: BoxHeightStyle.tight,
          selectionWidthStyle: BoxWidthStyle.tight,
          keyboardType: TextInputType.multiline,
          selectionColor: RiveTheme.of(context).colors.textSelection,
          onSubmitted: widget.onSubmitted,
          scrollPhysics: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;
}

/// We use a custom gesture detector here to allow for drag selection (otherwise
/// the editable text would scroll horizontally as the default behavior goes).
/// We simplified the logic here compared to the one in Flutter's TextField as
/// it was doing some word boundary selection in OSX that seemed
/// non-traditional. Definitely now how Flare works online and I couldn't
/// replicate their logic in any other app, so I dumbed it down to simple text
/// selection which seems to work well and will be deterministic across OSs.
class _EditorFieldGestureBuilder extends TextSelectionGestureDetectorBuilder {
  _EditorFieldGestureBuilder({
    @required _EditorTextFieldState state,
  })  : _state = state,
        super(delegate: state);

  final _EditorTextFieldState _state;

  @override
  void onTapDown(TapDownDetails details) {
    super.onTapDown(details);
    renderEditable.selectPosition(cause: SelectionChangedCause.tap);
    _state._requestKeyboard();
  }

  @override
  void onDragSelectionUpdate(
      DragStartDetails startDetails, DragUpdateDetails updateDetails) {
    // super.onDragSelectionUpdate(startDetails, updateDetails);return; luigi:
    // We can't let the native drag handler do its thing as it operates in
    // global coordinates, meaning the selection won't pin to the start if you
    // drag and scroll as it'll move while it scrolls. I made a video of that
    // issue here:
    // ![](https://assets.rvcd.in/text/native_selection.gif?raw=true)
    //
    // Here it is fixed using the original offset as the base and the newly
    // computed offset to the drag position as the extent.
    // ![](https://assets.rvcd.in/text/custom_selection.gif?raw=true)
    var position =
        renderEditable.getPositionForPoint(updateDetails.globalPosition);

    var selection = TextSelection(
      baseOffset: renderEditable.selection.baseOffset,
      extentOffset: position.offset,
      affinity: renderEditable.selection.affinity,
      isDirectional: true,
    );

    // Don't set renderEditable.selection directly as that doesn't allow edits
    // to delete the range. Calling onSelectionChanged is what the editable does
    // internally, so we're going to mimic that here.
    renderEditable?.onSelectionChanged(
        selection, renderEditable, SelectionChangedCause.drag);

    // keep focus (not sure if this is necessary)
    _state._requestKeyboard();

    // luigi: Make sure the position we're dragging to is visible (scroll it
    // into view if we're dragging to the edge of a field). Weird that Flutter's
    // not doing this. It also seems like the renderEditable.selection.extent
    // property isn't as advertised, the base and extent always seem to signify
    // the numerical begging and end, not the start/end of a selection (where
    // the end can be before the start if you're dragging backwards). If that
    // were the case we could just makes sure the extend is always in view. To
    // not deal with that, we just calculate the position of the text offset
    // we're dragging to and ensure it's in view.
    _state.editableTextKey.currentState?.bringIntoView(position);
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    editableText.hideToolbar();
    _state._requestKeyboard();
  }
}
