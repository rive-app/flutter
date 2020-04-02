import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'base_popup.dart';

typedef ListPopupItemBuilder<T> = Widget Function(
    BuildContext context, T item, bool isHovered);

/// Opens a popup with an arrow pointing to the area of interest/whatever
/// launched the popup.
class ArrowPopup {
  static Path _arrowFromDirection(PopupDirection direction) {
    if (direction.offsetVector.dx == 1) {
      return _pathArrowLeft;
    } else if (direction.offsetVector.dx == -1) {
      return _pathArrowRight;
    } else if (direction.offsetVector.dy == 1) {
      return _pathArrowUp;
    }
    return _pathArrowDown;
  }

  static Popup show(
    BuildContext context, {

    /// The widget builder for the content in the popup body.
    @required WidgetBuilder builder,

    /// Width of the popup panel, excluding arrows and directional padding.
    double width = 177,

    /// Offset used to shift the screen coordinates of the popup (useful when
    /// trying to align with some other content that may have relative offsets
    /// from what launched the popup).
    Offset offset = Offset.zero,

    /// Spacing applied between the area of interest and the popup in the
    /// direction this popup is docked/opened.
    double directionPadding = 16,

    /// Whether the arrow pointing to the area of interest that launched this
    /// popup should be shown.
    bool showArrow = true,

    /// Directional based offset applied to the arrow only in order to help
    /// align it to icons or other items in the area of interest that launched
    /// this popup.
    Offset arrowTweak = Offset.zero,

    /// The popup direction used to determine where this popup docks and which
    /// direction it opens in relative to the context that opened it.
    PopupDirection direction = PopupDirection.bottomToRight,

    /// Background color for the popup.
    Color background = const Color.fromRGBO(17, 17, 17, 1),

    /// Whether this popup wants its own close guard (a default close guard is
    /// provided which closes all open popups, use this if you want to keep
    /// other popups open when clicking off of this popup).
    bool includeCloseGuard = false,

    /// Callback invoked whenver the popup is closed.
    VoidCallback onClose,
  }) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final boxOffset = renderBox.localToGlobal(Offset.zero);

    return Popup.show(
      context,
      onClose: onClose,
      includeCloseGuard: includeCloseGuard,
      builder: (context) {
        return CustomMultiChildLayout(
          delegate: _ListPopupMultiLayoutDelegate(
            from: boxOffset & size,
            direction: direction,
            width: width,
            offset: offset,
            directionPadding: directionPadding,
            arrowTweak: arrowTweak,
          ),
          children: [
            if (showArrow)
              LayoutId(
                id: _ListPopupLayoutElement.arrow,
                child: CustomPaint(
                  painter: _ArrowPathPainter(
                    background,
                    _arrowFromDirection(direction),
                  ),
                ),
              ),
            LayoutId(
              id: _ListPopupLayoutElement.body,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(5.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3473),
                        offset: const Offset(0.0, 30.0),
                        blurRadius: 30,
                      )
                    ],
                  ),
                  child: builder(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Helper IDs used in the layout delegate to determine which child is which.
enum _ListPopupLayoutElement { arrow, body }

// Make sure to use floor here instead of round or it'll work in unexpected ways
// when the direction is negative on one axis.
Offset _wholePixels(Offset offset) =>
    Offset(offset.dx.floorToDouble(), offset.dy.floorToDouble());

/// A custom layout module for list popup which handles aligning the arrow and
/// content to the desired region of interest and expansion direction.
class _ListPopupMultiLayoutDelegate extends MultiChildLayoutDelegate {
  final Rect from;
  final PopupDirection direction;
  final double directionPadding;
  final double width;
  final Offset offset;
  final Offset arrowTweak;

  _ListPopupMultiLayoutDelegate({
    this.from,
    this.direction,
    this.directionPadding,
    this.width,
    this.offset,
    this.arrowTweak,
  });

  @override
  bool shouldRelayout(_ListPopupMultiLayoutDelegate oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.direction != direction ||
        oldDelegate.width != width ||
        oldDelegate.offset != offset ||
        oldDelegate.arrowTweak != arrowTweak;
  }

  @override
  void performLayout(Size size) {
    bool hasArrow = hasChild(_ListPopupLayoutElement.arrow);
    Size arrowSize = Size.zero;
    if (hasArrow) {
      arrowSize = layoutChild(
        _ListPopupLayoutElement.arrow,
        BoxConstraints.loose(size),
      );
    }
    
    Size bodySize = layoutChild(
      _ListPopupLayoutElement.body,
      width == null
          ? const BoxConstraints()
          : BoxConstraints.tightFor(width: width),
    );

    var vector = direction.offsetVector;

    var bodyPosition = from.topLeft +
        // Align to target of interest/dock position (from)
        direction.from.alongSize(from.size) -
        // Align the list relative to that position (to)
        direction.to.alongSize(bodySize) +
        // Offset by whatever list position tweak was passed in.
        offset +
        // Apply any directionaly padding
        (vector * directionPadding);

    if (hasArrow) {
      positionChild(
          _ListPopupLayoutElement.arrow,
          _wholePixels(from.topLeft +
              // Align to center of the area of interest
              Alignment.center.alongSize(from.size) +
              // Apply any implementation specific offset (we need to do this
              // both for the arrow and the body so the arrow lines up with the
              // body if it is shifted).
              offset +
              // Apply any directional padding.
              (vector * directionPadding) +
              // Center the arrow on the arrow of interest.
              Offset(
                  vector.dx * 0.5 * from.width, vector.dy * 0.5 * from.height) +
              // Apply any tweak to the centered arrow. For example, we need the
              // create popout to align to the icon in the entire popup button
              // but we use the whole popup button as the area of interest. So
              // here we can pass a simple offset to get the arrow to line up
              // with the icon.
              //
              // https://assets.rvcd.in/popup/arrow_tweak.png
              Offset(arrowTweak.dx * vector.dy.abs(),
                  arrowTweak.dy * vector.dx.abs())));

      // Move the body over by whatever space the arrow takes up.
      bodyPosition +=
          Offset(vector.dx * arrowSize.width, vector.dy * arrowSize.height);
    }

    positionChild(_ListPopupLayoutElement.body, _wholePixels(bodyPosition));
  }
}

final _pathArrowUp = Path()
  ..moveTo(-_arrowRadius, 0)
  ..lineTo(0, -_arrowRadius)
  ..lineTo(_arrowRadius, 0)
  ..close();

final _pathArrowDown = Path()
  ..moveTo(-_arrowRadius, 0)
  ..lineTo(0, _arrowRadius)
  ..lineTo(_arrowRadius, 0)
  ..close();

final _pathArrowLeft = Path()
  ..moveTo(0, -_arrowRadius)
  ..lineTo(-_arrowRadius, 0)
  ..lineTo(0, _arrowRadius)
  ..close();

final _pathArrowRight = Path()
  ..moveTo(0, -_arrowRadius)
  ..lineTo(_arrowRadius, 0)
  ..lineTo(0, _arrowRadius)
  ..close();

const double _arrowRadius = 6;

class _ArrowPathPainter extends CustomPainter {
  final Color color;
  final Path path;

  _ArrowPathPainter(this.color, this.path);

  @override
  bool shouldRepaint(_ArrowPathPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.path != path;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }
}
