import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/parametric_path.dart';

class ParametricPathConverter extends NodeConverter {
  ParametricPathConverter(
    ParametricPathBase path,
    RiveFile file,
    ContainerComponent maybeParent,
  ) : super(path, file, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final width = jsonData['width'];
    final height = jsonData['height'];

    final path = component as ParametricPathBase;

    if (width is num) {
      path.width = width.toDouble();
    }

    if (height is num) {
      path.height = height.toDouble();
    }
  }
}
