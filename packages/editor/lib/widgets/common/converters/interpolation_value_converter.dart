import 'package:flutter/foundation.dart';
import 'package:rive_core/animation/cubic_interpolator.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

class InterpolationValueConverter extends 
  InputValueConverter<InterpolationViewModel> {

  static final InterpolationValueConverter instance 
    = InterpolationValueConverter();

  @override
  InterpolationViewModel fromEditingValue(String value) {
    
    final trimmedValue = value.trim();
    final stringValues = trimmedValue.contains(',')
      ? trimmedValue.split(',')
      : trimmedValue.split(' ');

    for (var i = 0; i < stringValues.length; i++) {
      stringValues[i] = stringValues[i].trim();
    }

    if (listEquals(stringValues, ['-','-','-','-'])) {
      return const InterpolationViewModel(KeyFrameInterpolation.hold, null);
    }

    List<double> pointValues = [];
    stringValues.forEach((value) {
      final parsedValue = double.tryParse(value);
      if (parsedValue != null) {
        pointValues.add(parsedValue);
      }
    });

    if (pointValues.length < 4) {
      return null;
    }
    
    if (listEquals(pointValues, [0,0,1,1])) {
      return const InterpolationViewModel(KeyFrameInterpolation.linear, null);
    }

    var cubicInterpolator = CubicInterpolator();
    cubicInterpolator.x1 = pointValues[0];
    cubicInterpolator.y1 = pointValues[1];
    cubicInterpolator.x2 = pointValues[2];
    cubicInterpolator.y2 = pointValues[3];

    return InterpolationViewModel(
      KeyFrameInterpolation.cubic, cubicInterpolator);
 }

  @override
  String toEditingValue(InterpolationViewModel value) {
    
    switch (value.type) {
      case KeyFrameInterpolation.hold:
        return '-, -, -, -';
      case KeyFrameInterpolation.linear:
        return '0, 0, 1, 1';
      case KeyFrameInterpolation.cubic:
        var buffer = StringBuffer();
        final interpolator = value.interpolator;
        if (interpolator is CubicInterpolator) {
          final points = [
            interpolator.x1, interpolator.y1, 
            interpolator.x2, interpolator.y2];
          final parsedPoints = points.map(_parseValue);
          buffer.writeAll(parsedPoints, ', ');
        }
        return buffer.toString();
      default: return '';
    }
  }

  @override
  bool get allowDrag => false;

  String _parseValue(double value) {
    final roundedValue = value.toStringAsFixed(2);

    if (num.parse(roundedValue) % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    
    final exp = RegExp('^0+|0+\$');
    return roundedValue
      .replaceAll(exp, '')
      .replaceAll('-0.', '-.');
  }
}