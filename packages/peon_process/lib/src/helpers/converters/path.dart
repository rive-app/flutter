import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/points_path.dart';

class PathConverter extends NodeConverter {
  PathConverter(
      Path component, RiveFile context, ContainerComponent maybeParent)
      : super(component, context, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final isClosed = jsonData['isClosed'];
    final pathComponent = component as PointsPath;

    if (isClosed is bool) {
      pathComponent.isClosed = isClosed;
    }
  }
}
