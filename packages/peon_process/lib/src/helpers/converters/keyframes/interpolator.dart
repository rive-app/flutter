import 'package:rive_core/animation/cubic_interpolator.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';

class InterpolatorConverter {
  static KeyFrameInterpolation getInterpolator(int type) {
    switch (type) {
      case 0:
        return KeyFrameInterpolation.hold;
      case 2:
        return KeyFrameInterpolation.cubic;
      case 1:
      default:
        return KeyFrameInterpolation.linear;
    }
  }

  static CubicInterpolator cubicFrom(List curveValues) {
    assert(curveValues.length == 4);
    return CubicInterpolator()
      ..x1 = (curveValues[0] as num).toDouble()
      ..y1 = (curveValues[1] as num).toDouble()
      ..x2 = (curveValues[2] as num).toDouble()
      ..y2 = (curveValues[3] as num).toDouble();
  }
}
