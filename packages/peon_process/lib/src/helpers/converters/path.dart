import 'package:peon_process/converters.dart';
import 'package:rive_core/bones/skinnable.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/points_path.dart';

/// 'ConnectedBones' in Flare are now called 'Tendons' in Rive.
class TendonConverter {
  /// This is the id of the bone component to retrieve at a later step
  final int boneId;
  final Skinnable skinnable;
  Mat2D tendonBind;

  TendonConverter(this.boneId, this.skinnable)
      : assert(boneId is num),
        assert(boneId > 0);

  void deserialize(Map<String, Object> jsonData) {
    final bind = jsonData['bind'];

    if (bind is List) {
      tendonBind = Mat2D();
      tendonBind[0] = (bind[0] as num).toDouble();
      tendonBind[1] = (bind[1] as num).toDouble();
      tendonBind[2] = (bind[2] as num).toDouble();
      tendonBind[3] = (bind[3] as num).toDouble();
      tendonBind[4] = (bind[4] as num).toDouble();
      tendonBind[5] = (bind[5] as num).toDouble();
    }
  }
}

class SkinConverter {
  final Skinnable skinnable;
  final Mat2D overrideWorldTransform;

  const SkinConverter(this.skinnable, this.overrideWorldTransform);
}

class PathConverter extends NodeConverter {
  PathConverter(
      PointsPath component, RiveFile context, ContainerComponent maybeParent)
      : super(component, context, maybeParent);

  final tendons = <TendonConverter>[];
  SkinConverter skinConverter;

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final isClosed = jsonData['isClosed'];
    final connectedBones = jsonData['connectedBones'];
    final owt = jsonData['overrideWorldTransform'];

    final pathComponent = component as PointsPath;

    if (isClosed is bool) {
      pathComponent.isClosed = isClosed;
    }

    if (owt is List) {
      final skinOWT = Mat2D();
      skinConverter = SkinConverter(pathComponent, skinOWT);
      skinOWT[0] = (owt[0] as num).toDouble();
      skinOWT[1] = (owt[1] as num).toDouble();
      skinOWT[2] = (owt[2] as num).toDouble();
      skinOWT[3] = (owt[3] as num).toDouble();
      skinOWT[4] = (owt[4] as num).toDouble();
      skinOWT[5] = (owt[5] as num).toDouble();
    }

    if (connectedBones is List) {
      for (var i = 0; i < connectedBones.length; i++) {
        final connection = connectedBones[i] as Map<String, Object>;
        final id = connection['id'];

        if (id is int) {
          final tConverter = TendonConverter(id, pathComponent)
            ..deserialize(connection);
          tendons.add(tConverter);
        }
      }
    }
  }
}
