import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:tree_widget/flat_tree_item.dart';

/// Callback for creating the background of a tree row. This has some special
/// state management for conditions like allowing dropping above/below/into an
/// item. The TreeView is specifically built to allow theming all aspects,
/// including stylings for drag and drop.
class DropItemBackground extends StatelessWidget {
  const DropItemBackground(this.dropState, this.selectionState,
      {this.selectedElevation = 0.0});

  final DropState dropState;
  final SelectionState selectionState;
  final double selectedElevation;

  @override
  Widget build(BuildContext context) {
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
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(87, 165, 224, 0.3),
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
            );
          case SelectionState.selected:
            return Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(87, 165, 224, 1.0),
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB((0.28 * 255).round(), 0, 88, 166),
                    offset: Offset(0.0, 6),
                    blurRadius: 10.0,
                  ),
                ],
              ),
            );
          case SelectionState.none:
            break;
        }
        break;
    }

    return Container(color: Colors.transparent);
  }
}
