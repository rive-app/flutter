import 'dart:math';
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart'
    as rive_linear_gradient;
import 'package:rive_core/shapes/paint/radial_gradient.dart'
    as rive_radial_gradient;

void addGradient(DrawableGradient gradient, RiveFile file, ShapePaint paint,
    Rect bounds, Offset shapeOffset) {
  rive_linear_gradient.LinearGradient tmp;

  double _translate(
      double originalValue, double scaleValue, double translateValue) {
    if (gradient.unitMode == GradientUnitMode.objectBoundingBox) {
      return translateValue + originalValue * scaleValue;
    } else {
      return originalValue + translateValue;
    }
  }

  if (gradient is DrawableLinearGradient) {
    tmp = rive_linear_gradient.LinearGradient();

    tmp.startX = _translate(
      gradient.from.dx,
      bounds.width,
      bounds.left - shapeOffset.dx,
    );
    tmp.startY = _translate(
      gradient.from.dy,
      bounds.height,
      bounds.top - shapeOffset.dy,
    );
    tmp.endX = _translate(
      gradient.to.dx,
      bounds.width,
      bounds.left - shapeOffset.dx,
    );
    tmp.endY = _translate(
      gradient.to.dy,
      bounds.height,
      bounds.top - shapeOffset.dy,
    );
  } else if (gradient is DrawableRadialGradient) {
    tmp = rive_radial_gradient.RadialGradient();

    var offset = sqrt(pow(gradient.radius, 2) / 2);

    tmp.startX = _translate(
      gradient.center.dx,
      bounds.width,
      bounds.left - shapeOffset.dx,
    );
    tmp.startY = _translate(
      gradient.center.dy,
      bounds.height,
      bounds.top - shapeOffset.dy,
    );
    tmp.endX = _translate(
      gradient.center.dx - offset,
      bounds.width,
      bounds.left - shapeOffset.dx,
    );
    tmp.endY = _translate(
      gradient.center.dy - offset,
      bounds.height,
      bounds.top - shapeOffset.dy,
    );
  }
  file.addObject(tmp);
  var i = 0;
  while (i < gradient.offsets.length) {
    var stop = GradientStop();
    stop.color = gradient.colors[i];
    stop.position = gradient.offsets[i];
    file.addObject(stop);
    tmp.appendChild(stop);
    i += 1;
  }
  paint.appendChild(tmp);
}
