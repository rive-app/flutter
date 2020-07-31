import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/stroke.dart';


class StrokeColorConverter extends StrokeBaseConverter with ColorExtractor {
  StrokeColorConverter(
    Stroke component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super(component, context, maybeParent);

  @override
  Stroke get paint => component as Stroke;

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    extractColor(jsonData);
  }
}

class StrokeGradientConverter extends StrokeBaseConverter with ColorExtractor {
  StrokeGradientConverter(
      Stroke component, RiveFile context, ContainerComponent maybeParent)
      : super(component, context, maybeParent);

  @override
  Stroke get paint => component as Stroke;

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    extractGradient(jsonData);
  }
}
