import 'package:flutter/widgets.dart';

/// Important that this uses BouncingScrollPhysics in order to overcome the edge
/// case when changing content size at the bottom of the scroll list:
/// https://github.com/rive-app/rive/issues/621
/// We've now made this public as the tab bar needs it too:
/// https://github.com/rive-app/rive/issues/1308
class BouncyCustomScrollController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition oldPosition) {
    return ScrollPositionWithSingleContext(
      // If you change this please check issue #621 and validate that resizing
      // the scroll content works at the bounds and syncs both key and tree
      // views.
      physics: const _ClampNeverScrollPhysics(),
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _ClampNeverScrollPhysics extends ScrollPhysics {
  const _ClampNeverScrollPhysics({ScrollPhysics parent})
      : super(parent: parent);

  @override
  _ClampNeverScrollPhysics applyTo(ScrollPhysics ancestor) {
    return _ClampNeverScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => false;

  @override
  bool get allowImplicitScrolling => false;

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return _ForceSetPositionSimulation(position.pixels
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble());
    }
    return null;
  }
}

class _ForceSetPositionSimulation extends Simulation {
  double position;
  _ForceSetPositionSimulation(this.position);
  @override
  double dx(double time) {
    return 0;
  }

  @override
  bool isDone(double time) {
    return true;
  }

  @override
  double x(double time) {
    return position;
  }
}
