import 'package:peon_process/src/helpers/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';

class ShapePaintConverter extends ComponentConverter {
  ShapePaintConverter(
    ShapePaintBase component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super(component, context, maybeParent);

  /// No need for a custom deserialize() since Flare files don't export
  /// whether Fills or Strokes are visible or not.
  /// Let them always show.
}
