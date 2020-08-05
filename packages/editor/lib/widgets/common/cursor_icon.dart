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
        delegate: const _CursorPositionDelegate(Alignment.center),
        child: TintedIcon(
          icon: icon,
          // intentionally null so that the icon is 'au naturel'
          color: null,
        ),
      ),
    );
  }

  static CursorInstance build(
      Cursor cursor, Iterable<PackedIcon> icon, Alignment alignment) {
    return cursor.withBuilder(
      (context) => CustomSingleChildLayout(
        delegate: _CursorPositionDelegate(alignment),
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
  const _CursorPositionDelegate(this.alignment);

  final Alignment alignment;
  @override
  bool shouldRelayout(_CursorPositionDelegate oldDelegate) => false;

  @override
  Size getSize(BoxConstraints constraints) => constraints.smallest;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
      -childSize.width / 2 - alignment.x * childSize.width / 2,
      -childSize.height / 2 - alignment.y * childSize.height / 2);
}
