import 'package:cursor/cursor_view.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Helper to use Rive Icons as cursors on the CursorView.
class CursorIcon {
  /// Show a cursor icon.
  static CursorInstance show(BuildContext context, Iterable<PackedIcon> icon) {
    return Cursor.change(
      context,
      (context) => CustomSingleChildLayout(
        delegate: const _CursorPositionDelegate(),
        child: TintedIcon(
          icon: icon,
          // intentionally null so that the icon is 'au naturel'
          color: null,
        ),
      ),
    );
  }

  static CursorInstance build(Cursor cursor, Iterable<PackedIcon> icon) {
    return cursor.withBuilder(
      (context) => CustomSingleChildLayout(
        delegate: const _CursorPositionDelegate(),
        child: TintedIcon(
          icon: icon,
          // intentionally null so that the icon is 'au naturel'
          color: null,
        ),
      ),
    );
  }
}

/// Custom positioner that places the cursor icon centered on its origin.
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
