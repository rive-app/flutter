import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/shape.dart';

class ShapeConverter extends DrawableConverter {
  ShapeConverter(
    ShapeBase shape,
    RiveFile file,
    ContainerComponent maybeParent,
  ) : super(shape, file, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    // TODO: check if anything's missing, or skip this subclass?
  }
}
