import 'package:flutter/rendering.dart';

/// The direction in which to open a popup relative to an area of interest. This
/// takes into account where the popup docks relative to the area of interest
/// and then how it aligns and grows out from that area of interest. This is
/// done with two alignment objects, the [from] detailing where to align from
/// the area of interest's offset and size and the [to] dictating which edge of
/// the popup list is matched to the [from]'s origin. The [offsetVector] is used
/// as a helper to indicate the genral direction the popup is opening in. It is
/// represented as a unit vector and only travels in discrete axis directions.
class PopupDirection {
  final Alignment from;
  final Alignment to;
  final Offset offsetVector;

  const PopupDirection({
    this.from,
    this.to,
    this.offsetVector,
  });

  /// Open the popup on the bottom of the area of interest and align the
  /// content to the left edge of the area of interest so it grows out towards
  /// the right.
  ///
  /// ![](https://assets.rvcd.in/popup/bottomToRight.png)
  static const PopupDirection bottomToRight = PopupDirection(
    from: Alignment.bottomLeft,
    to: Alignment.topLeft,
    offsetVector: Offset(0, 1),
  );

  /// Open the popup on the bottom of the area of interest and align the content
  /// to the right edge of the area of interest so it grows out towards the
  /// left.
  ///
  /// ![](https://assets.rvcd.in/popup/bottomToLeft.png)
  static const PopupDirection bottomToLeft = PopupDirection(
    from: Alignment.bottomRight,
    to: Alignment.topRight,
    offsetVector: Offset(0, 1),
  );

  /// Open the popup on the bottom of the area of interest and center the list
  /// horizontally under it.
  ///
  /// ![](https://assets.rvcd.in/popup/bottomToCenter.png)
  static const PopupDirection bottomToCenter = PopupDirection(
    from: Alignment.bottomCenter,
    to: Alignment.topCenter,
    offsetVector: Offset(0, 1),
  );

  /// Open the popup on the right of the area of interest and align the content
  /// to the bottom edge of the area of interest so it grows out towards the top
  /// of the screen.
  ///
  /// ![](https://assets.rvcd.in/popup/rightToTop.png)
  static const PopupDirection rightToTop = PopupDirection(
    from: Alignment.bottomRight,
    to: Alignment.bottomLeft,
    offsetVector: Offset(1, 0),
  );

  /// Open the popup on the right of the area of interest and center the list
  /// vertically next to it.
  ///
  /// ![](https://assets.rvcd.in/popup/rightToCenter.png)
  static const PopupDirection rightToCenter = PopupDirection(
    from: Alignment.centerRight,
    to: Alignment.centerLeft,
    offsetVector: Offset(1, 0),
  );

  /// Open the popup on the right of the area of interest and align the content
  /// to the top edge of the area of interest so it grows out towards the bottom
  /// of the screen.
  ///
  /// ![](https://assets.rvcd.in/popup/rightToBottom.png)
  static const PopupDirection rightToBottom = PopupDirection(
    from: Alignment.topRight,
    to: Alignment.topLeft,
    offsetVector: Offset(1, 0),
  );

  /// Open the popup on the top of the area of interest and align the content to
  /// the right edge of the area of interest so it grows out towards the left of
  /// the screen.
  ///
  /// ![](https://assets.rvcd.in/popup/topToLeft.png)
  static const PopupDirection topToLeft = PopupDirection(
    from: Alignment.topRight,
    to: Alignment.bottomRight,
    offsetVector: Offset(0, -1),
  );

  /// Open the popup on the top of the area of interest and center the list
  /// horizontally above it.
  ///
  /// ![](https://assets.rvcd.in/popup/topToCenter.png)
  static const PopupDirection topToCenter = PopupDirection(
    from: Alignment.topCenter,
    to: Alignment.bottomCenter,
    offsetVector: Offset(0, -1),
  );

  /// Open the popup on the top of the area of interest and align the content to
  /// the left edge of the area of interest so it grows out towards the right of
  /// the screen.
  ///
  /// ![](https://assets.rvcd.in/popup/topToRight.png)
  static const PopupDirection topToRight = PopupDirection(
    from: Alignment.topLeft,
    to: Alignment.bottomLeft,
    offsetVector: Offset(0, -1),
  );

  /// Open the popup on the left of the area of interest and align the content
  /// to the bottom edge of the area of interest so it grows out towards the top
  /// of the screen.
  ///
  /// ![](https://assets.rvcd.in/popup/leftToTop.png)
  static const PopupDirection leftToTop = PopupDirection(
    from: Alignment.bottomLeft,
    to: Alignment.bottomRight,
    offsetVector: Offset(-1, 0),
  );

  /// Open the popup on the left of the area of interest and center the list
  /// vertically next to it.
  ///
  /// ![](https://assets.rvcd.in/popup/leftToCenter.png)
  static const PopupDirection leftToCenter = PopupDirection(
    from: Alignment.centerLeft,
    to: Alignment.centerRight,
    offsetVector: Offset(-1, 0),
  );


  /// Open the popup on the left of the area of interest and align the content
  /// to the top edge of the area of interest so it grows out towards the bottom
  /// of the screen.
  ///
  /// ![](https://assets.rvcd.in/popup/leftToBottom.png)
  static const PopupDirection leftToBottom = PopupDirection(
    from: Alignment.topLeft,
    to: Alignment.topRight,
    offsetVector: Offset(-1, 0),
  );

  @override
  bool operator ==(Object other) {
    return other is PopupDirection && other.from == from && other.to == to;
  }

  @override
  int get hashCode => hashValues(from.x, from.y, to.x, to.y);
}
