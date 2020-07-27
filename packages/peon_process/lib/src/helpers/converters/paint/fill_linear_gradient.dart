import 'package:peon_process/src/helpers/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';

class LinearGradientConverter extends ComponentConverter {
  LinearGradientConverter(
    LinearGradientBase component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super(component, context, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final color = jsonData['color'];

    if (color is List) {
      assert(color.every((Object e) => e is num));

      final gradient = component as LinearGradientBase;
      // TODO: Shape Bounds.
      // Look at inspecting_color.dart -- this needs the shape

      final stops = <GradientStop>[];
      // TODO: deserialize color & color stops

      final ctx = component.context;
      stops.forEach(ctx.addObject);
      stops.forEach(gradient.appendChild);
    }
  }
}
