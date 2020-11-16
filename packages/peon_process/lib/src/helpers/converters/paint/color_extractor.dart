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
    final opacity = jsonData['opacity'];

    if (color is List) {
      assert(color.every((Object e) => e is num));
      assert(opacity is num);

      final colorValue = Color.fromRGBO(
        ((color[0] as num) * 255).toInt(),
        ((color[1] as num) * 255).toInt(),
        ((color[2] as num) * 255).toInt(),
        (opacity as num).toDouble(),
      );

      var fillColor = paint.children.firstWhere((child) => child is SolidColor);
      (fillColor as SolidColor).color = colorValue;
    }
  }

  void extractGradient(Map<String, Object> jsonData) {
    // Color stops in Flare are maintained in a flat list of numbers:
    // [ R, G, B, A, D, ...[other stops] ]
    // R = Red, G = Green, B = Blue, A = Alpha
    // and D is a number [0, 1] that is the distance of this stop
    // from the start.
    final colorStops = jsonData['colorStops'];
    // Starting position in local coordinates for this gradient
    final start = jsonData['start'];
    // Ending position in local coordinates for this gradient
    final end = jsonData['end'];
    final type = jsonData['type'];
    final opacity = jsonData['opacity'];

    final isRadial = (type as String).toLowerCase().contains('radial');
    final gradient = isRadial ? RadialGradient() : LinearGradient();

    if (start is List) {
      gradient
        ..startX = (start[0] as num).toDouble()
        ..startY = (start[1] as num).toDouble();
    }

    if (end is List) {
      gradient
        ..endX = (end[0] as num).toDouble()
        ..endY = (end[1] as num).toDouble();
    }

    if (opacity is num) {
      gradient.opacity = opacity.toDouble();
    }

    final stops = <GradientStop>[];
    if (colorStops is List) {
      // final numStops = colorStops.length / 5;
      int i = 0;
      while (i < colorStops.length) {
        final r = colorStops[i++] as num;
        final g = colorStops[i++] as num;
        final b = colorStops[i++] as num;
        final a = colorStops[i++] as num;
        final d = colorStops[i++] as num;
        final stop = GradientStop()
          ..color = Color.fromRGBO(
            (r * 255).toInt(),
            (g * 255).toInt(),
            (b * 255).toInt(),
            a.toDouble(),
          )
          ..position = d.toDouble();
        stops.add(stop);
      }
    }

    final context = paint.context;

    context.batchAdd(() {
      // Remove Solid Color that was added to properly initialize this Fill/Stroke.
      paint.children.removeWhere((element) => element is SolidColor);
      context.addObject(gradient);
      stops.forEach((stop) {
        context.addObject(stop);
        gradient.appendChild(stop);
      });
      paint.appendChild(gradient);
    });
  }
}
