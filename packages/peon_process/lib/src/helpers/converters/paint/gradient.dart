import 'dart:ui';

import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_core/shapes/paint/radial_gradient.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';

/// Gradients are used in Fills & Strokes. Instead of relying on two separate
/// subclasses for extracting data, Fill & Strokes are both using this as a
/// mixin to deserialize data. (e.g. [FillGradientConverter])
abstract class ColorExtractor {
  ShapePaintBase get paint;

  void extractColor(Map<String, Object> jsonData) {
    final color = jsonData['color'];

    if (color is List) {
      assert(color.every((Object e) => e is num));

      final colorValue = Color.fromRGBO(
        ((color[0] as num) * 255).toInt(),
        ((color[1] as num) * 255).toInt(),
        ((color[2] as num) * 255).toInt(),
        (color[3] as num).toDouble(),
      );
      final solidColor = SolidColor()..color = colorValue;

      final ctx = paint.context;
      ctx.batchAdd(() {
        ctx.addObject(solidColor);
        paint.appendChild(solidColor);
      });
    }
  }

  void extractGradient(Map<String, Object> jsonData) {
    // Color stops in Flare are maintained in a flat list of numbers:
    // [ R, G, B, A, D, ...[other stops] ]
    // R = Red, G = Green, B = Blue, A = Alpha
    // and D is a number [0, 1] that is the distance of this stop from the start.
    final colorStops = jsonData["colorStops"];
    // Starting position in local coordinates for this gradient
    final start = jsonData["start"];
    // Ending position in local coordinates for this gradient
    final end = jsonData["end"];
    final type = jsonData["type"];
    final isRadial = (type as String).toLowerCase().contains("radial");
    final gradient = isRadial ? RadialGradient() : LinearGradient();

    if (start is List) {
      gradient
        ..startX = start[0].toDouble()
        ..startY = start[1].toDouble();
    }

    if (end is List) {
      gradient
        ..endX = end[0].toDouble()
        ..endY = end[1].toDouble();
    }

    final stops = <GradientStop>[];
    if (colorStops is List) {
      // final numStops = colorStops.length / 5;
      int i = 0;
      while (i < colorStops.length) {
        final r = colorStops[i++];
        final g = colorStops[i++];
        final b = colorStops[i++];
        final a = colorStops[i++];
        final d = colorStops[i++];
        final stop = GradientStop()
          ..color = Color.fromRGBO(
            ((r as num) * 255).toInt(),
            ((g as num) * 255).toInt(),
            ((b as num) * 255).toInt(),
            (a as num).toDouble(),
          )
          ..position = d.toDouble();
        stops.add(stop);
      }
    }

    final context = paint.context;

    context.batchAdd(() {
      context.addObject(gradient);
      stops.forEach((stop) {
        context.addObject(stop);
        gradient.appendChild(stop);
      });
      paint.appendChild(gradient);
    });
  }
}
