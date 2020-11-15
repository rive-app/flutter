import 'package:peon_process/converters.dart';
import 'package:rive_core/bones/skin.dart';
import 'package:rive_core/bones/skinnable.dart';
import 'package:rive_core/bones/tendon.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/points_path.dart';

/// 'ConnectedBones' in Flare are now called 'Tendons' in Rive.
class TendonConverter {
  /// This is the id of the bone component to retrieve at a later step
  final int boneId;
  /// The bone iteration index, as this'll require reconciliation with
  /// the path point weights.
  final int boneIdx;
  final Skinnable skinnable;
  final Tendon tendon;
  final Skin skin;

  TendonConverter(this.boneId, this.boneIdx, this.skinnable)
      : assert(boneId is num),
        assert(boneId > 0),
        tendon = Tendon(),
        skin = Skin();

  void deserialize(Map<String, Object> jsonData) {
    final bind = jsonData['bind'];
    final length = jsonData['length'];

    if (bind is List) {
      tendon
        ..xx = (bind[0] as num).toDouble()
        ..xy = (bind[1] as num).toDouble()
        ..yx = (bind[2] as num).toDouble()
        ..yy = (bind[3] as num).toDouble()
        ..tx = (bind[4] as num).toDouble()
        ..ty = (bind[5] as num).toDouble();
    }
  }
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
          final tConverter = TendonConverter(id, i, pathComponent)
            ..deserialize(connection);
          tendons.add(tConverter);
        }
      }
    }
  }
}
