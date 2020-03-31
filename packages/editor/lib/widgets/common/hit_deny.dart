import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Any hit test done by this widget will be denied unless somewhere in the
/// children a [HitAllow] is encountered.
///
/// Make your pointer feel shame: https://www.youtube.com/watch?v=x1xzoOpv8xY
class HitDeny extends SingleChildRenderObjectWidget {
  const HitDeny({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  _RenderHitDeny createRenderObject(BuildContext context) {
    return _RenderHitDeny();
  }
}

/// Render object for the [HitDeny].
class _RenderHitDeny extends RenderProxyBox {
  _RenderHitDeny({
    RenderBox child,
  }) : super(child);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {}

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    var r = super.hitTestChildren(result, position: position);
    if (!r) {
      // early out
      return false;
    }

    // Ok our children want the hit, but let's make sure something opened the
    // gate.
    for (final crumb in result.path) {
      if (crumb.target is RenderHitAllow) {
        return true;
      }
    }

    return false;
  }
}

/// Use as a gate to re-allow hit testing inside of a [HitDeny].
///
/// Back in favor: https://www.youtube.com/watch?v=wc0EtpqwCjU
class HitAllow extends SingleChildRenderObjectWidget {
  const HitAllow({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderHitAllow createRenderObject(BuildContext context) {
    return RenderHitAllow();
  }
}

class RenderHitAllow extends RenderProxyBox {
  RenderHitAllow({
    RenderBox child,
  }) : super(child);
}
