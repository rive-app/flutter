import 'package:cursor/cursor_view.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class CursorIcon {
  static void show(BuildContext context, String icon) {
    Cursor.change(
      context,
      (context) => CustomSingleChildLayout(
        delegate: const _CursorPositionDelegate(),
        child: TintedIcon(
          icon: icon,
          color: Colors.white,
        ),
      ),
    );
  }

  static void reset(BuildContext context) => Cursor.reset(context);
}

class _CursorPositionDelegate extends SingleChildLayoutDelegate {
  const _CursorPositionDelegate();

  @override
  bool shouldRelayout(_CursorPositionDelegate oldDelegate) => false;

  @override
  Size getSize(BoxConstraints constraints) => constraints.smallest;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      Offset(-childSize.width / 2, -childSize.height / 2);
}
