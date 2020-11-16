import 'package:peon_process/converters.dart';
import 'package:rive_core/bones/skinnable.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/points_path.dart';

/// 'ConnectedBones' in Flare are now called 'Tendons' in Rive.
class TendonConverter {
  /// This is the id of the bone component to retrieve at a later step
  final int boneId;
  final Skinnable skinnable;

  const TendonConverter(this.boneId, this.skinnable)
      : assert(boneId is num),
        assert(boneId > 0);
}

class PathConverter extends NodeConverter {
  PathConverter(
      PointsPath component, RiveFile context, ContainerComponent maybeParent)
      : super(component, context, maybeParent);

  final tendons = <TendonConverter>[];

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final isClosed = jsonData['isClosed'];
    final connectedBones = jsonData['connectedBones'];

    final pathComponent = component as PointsPath;

    if (isClosed is bool) {
      pathComponent.isClosed = isClosed;
    }

    if (connectedBones is List) {
      for (var i = 0; i < connectedBones.length; i++) {
        final connection = connectedBones[i] as Map<String, Object>;
        final id = connection['id'];

        if (id is int) {
          final tConverter = TendonConverter(id, pathComponent);
          tendons.add(tConverter);
        }
      }
    }
  }
}
