import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe_color.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';

class KeyFrameRadialGradientConverter extends KeyFrameGradientConverter {
  /// Radial Gradients in Flare had the same format as normal gradients, with
  /// an additional value at the start: the secondary radius scale.
  /// We just skip it fro now.
  KeyFrameRadialGradientConverter(
      List value, int interpolatorType, List interpolatorCurve)
      : super(value.skip(1).toList(growable: false), interpolatorType,
            interpolatorCurve);
}

class KeyFrameGradientConverter extends KeyFrameSolidColorConverter {
  /// Gradient keys were stored in Flare as a contiguous list
  /// with the following format:
  /// [
  ///  starX, startY, endX, endY,
  ///  r1, g1, b1, a1, d1,
  ///  r2, g2, b2, a2, d2,
  ///  ...more stops
  ///  ]
  /// So the number of items in the list, minus the first 4 elements, should
  /// be a multiple of 5.
  KeyFrameGradientConverter(
      List value, int interpolatorType, List interpolatorCurve)
      : assert((value.length - 4) % 5 == 0),
        startX = (value[0] as num).toDouble(),
        startY = (value[1] as num).toDouble(),
        endX = (value[2] as num).toDouble(),
        endY = (value[3] as num).toDouble(),
        super(value, interpolatorType, interpolatorCurve);

  final double startX, startY;
  final double endX, endY;

  Component getGradientComponent(ShapePaintContainer paintContainer) {
    final fill = paintContainer.fills.first;
    final gradientFill = fill.children.first;

    if (gradientFill is LinearGradient) {
      return gradientFill;
    }

    print('Leftover GradientFill Keyframe? ${gradientFill.runtimeType}');
    return null;
  }

  @override
  void convertKey(
      Component paintContainer, LinearAnimation animation, int frame) {
    if (paintContainer is! ShapePaintContainer) {
      throw UnsupportedError(
          'Cannot add fill to ${paintContainer.runtimeType}');
    }

    final gradientComponent =
        getGradientComponent(paintContainer as ShapePaintContainer);
    if (gradientComponent == null) {
      return;
    }

    generateKey<KeyFrameDouble>(gradientComponent, animation, frame,
        LinearGradientBase.startXPropertyKey)
      ..value = startX;

    generateKey<KeyFrameDouble>(gradientComponent, animation, frame,
        LinearGradientBase.startYPropertyKey)
      ..value = startY;

    generateKey<KeyFrameDouble>(
        gradientComponent, animation, frame, LinearGradientBase.endXPropertyKey)
      ..value = endX;

    generateKey<KeyFrameDouble>(
        gradientComponent, animation, frame, LinearGradientBase.endYPropertyKey)
      ..value = endY;

    final gradientStops = (gradientComponent as LinearGradient).gradientStops;
    final stopValuesList = stopValues;

    assert(stopValuesList.length == gradientStops.length);

    for (int i = 0; i < stopValuesList.length; i++) {
      final stopValue = stopValuesList[i];
      final stopComponent = gradientStops[i];

      generateKey<KeyFrameColor>(stopComponent, animation, frame,
          GradientStopBase.colorValuePropertyKey)
        ..value = getColorValue(stopValue.color);

      generateKey<KeyFrameDouble>(
          stopComponent, animation, frame, GradientStopBase.positionPropertyKey)
        ..value = stopValue.d.toDouble();
    }
  }

  List<_ColorStop> get stopValues {
    final stopValues = value as List;
    final stops = <_ColorStop>[];

    // First 4 values have already been deserialized in the constructor.
    int i = 4;

    while (i < stopValues.length) {
      final r = stopValues[i++];
      final g = stopValues[i++];
      final b = stopValues[i++];
      final a = stopValues[i++];
      final d = stopValues[i++];
      final stop = _ColorStop(r, g, b, a, d);
      stops.add(stop);
    }

    return stops;
  }
}

class _ColorStop {
  const _ColorStop(this.r, this.g, this.b, this.a, this.d);
  final num r, g, b, a, d;
  List<num> get color => [r, g, b, a];
}

class KeyFrameStrokeRadialGradientConverter
    extends KeyFrameStrokeGradientConverter {
  KeyFrameStrokeRadialGradientConverter(
      List value, int interpolatorType, List interpolatorCurve)
      : super(value.skip(1).toList(growable: false), interpolatorType,
            interpolatorCurve);
}

class KeyFrameStrokeGradientConverter extends KeyFrameGradientConverter {
  KeyFrameStrokeGradientConverter(
      List value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  Component getGradientComponent(ShapePaintContainer paintContainer) {
    final stroke = paintContainer.strokes.first;
    final gradientStroke = stroke.children.first;

    if (gradientStroke is LinearGradient) {
      return gradientStroke;
    }

    print('Leftover GradientFill Keyframe? ${gradientStroke.runtimeType}');
    return null;
  }
}
