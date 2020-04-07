import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:tree_widget/flat_tree_item.dart';

/// Callback for creating the background of a tree row. This has some special
/// state management for conditions like allowing dropping above/below/into an
/// item. The TreeView is specifically built to allow theming all aspects,
/// including stylings for drag and drop.
class DropItemBackground extends StatelessWidget {
  const DropItemBackground(this.dropState, this.selectionState,
      {this.child, this.color});

  final DropState dropState;
  final SelectionState selectionState;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    switch (dropState) {
      case DropState.parent:
        return Padding(
          padding: const EdgeInsets.all(2),
          child: DottedBorder(
            color: const Color.fromRGBO(87, 165, 224, 1.0),
            strokeWidth: 2,
            borderType: BorderType.RRect,
            dashPattern: const [7, 5],
            radius: const Radius.circular(5),
            child: Container(),
          ),
        );
      case DropState.above:
        return Container(
          clipBehavior: Clip.none,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color.fromRGBO(87, 165, 224, 1.0),
                width: 2.0,
                style: BorderStyle.solid,
              ),
            ),
          ),
        );
      case DropState.below:
        return Transform.translate(
          offset: const Offset(0, 2),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color.fromRGBO(87, 165, 224, 1.0),
                  width: 2.0,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        );
      case DropState.into:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(87, 165, 224, 1.0),
              width: 2.0,
              style: BorderStyle.solid,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
        );
      case DropState.none:
        switch (selectionState) {
          case SelectionState.hovered:
            return SelectionBorder(
                child: child, color: color ?? colors.fileHoveredBlue);
          case SelectionState.selected:
            return SelectionBorder(
              child: child,
              color: color ?? colors.fileSelectedBlue,
            );
          case SelectionState.none:
            break;
        }
        break;
    }

    return SizedBox(child: child);
  }
}

/// Custom selection border to attempt using custom blend modes for the
/// selection state. We didn't end up using the custom blend modes as they cause
/// visual glitches. There must be some widget in the scrollview that saves a
/// layer and breaks the blend modes...haven't found it yet. Keeping this widget
/// as it's still lighter weight at runtime than a Container.
class SelectionBorder extends SingleChildRenderObjectWidget {
  final Color color;

  const SelectionBorder({
    @required this.color,
    Key key,
    Widget child,
  }) : super(
          key: key,
          child: child,
        );

  @override
  _RenderSelectionBorder createRenderObject(BuildContext context) {
    return _RenderSelectionBorder(color: color);
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderSelectionBorder renderObject) {
    renderObject.color = color;
  }
}

class _RenderSelectionBorder extends RenderProxyBox {
  final Paint _borderPaint;

  _RenderSelectionBorder({RenderBox child, Color color})
      : _borderPaint = Paint()..color = color,
        super(child);

  Color get color => _borderPaint.color;
  set color(Color value) {
    if (_borderPaint.color == value) {
      return;
    }
    _borderPaint.color = value;
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;

    var path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(offset & size, const Radius.circular(5)));

    canvas.drawPath(path, _borderPaint);

    super.paint(context, offset);
  }
}
