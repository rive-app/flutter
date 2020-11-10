import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';

class ShapePaintConverter extends ComponentConverter {
  ShapePaintConverter(
    ShapePaintBase component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super.init(component) {
    context.batchAdd(() {
      final solidColor = SolidColor();
      context.addObject(component);
      context.addObject(solidColor);

      component.appendChild(solidColor);
      maybeParent?.appendChild(component);
    });
  }

  /// No need for a custom deserialize() since Flare files don't export
  /// whether Fills or Strokes are visible or not.
  /// Let them always show.
}
