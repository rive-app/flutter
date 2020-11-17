import 'package:peon_process/converters.dart';
import 'package:rive_core/bones/skeletal_component.dart';
import 'package:rive_core/bones/skin.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/points_path.dart';

/// 'ConnectedBones' in Flare are now called 'Tendons' in Rive.
class TendonFinalizer extends ConversionFinalizer {
  /// This is the id of the bone component to retrieve at a later step
  final String boneId;
  Mat2D tendonBind;

  TendonFinalizer(this.boneId, PointsPath skinnable) : super(skinnable);

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

  @override
  void finalize(Map<String, Component> fileComponents) {
    final pointsPath = component as PointsPath;
    final rf = riveFile;

    rf.batchAdd(() {
      final bone = fileComponents[boneId] as SkeletalComponent;
      final tendon = Skin.bind(bone, pointsPath);

      if (tendonBind != null) {
        tendon
          ..xx = tendonBind[0]
          ..xy = tendonBind[1]
          ..yx = tendonBind[2]
          ..yy = tendonBind[3]
          ..tx = tendonBind[4]
          ..ty = tendonBind[5];
      }
    });
  }
}

class SkinFinalizer extends ConversionFinalizer {
  final Mat2D overrideWorldTransform;

  const SkinFinalizer(PointsPath skinnable, this.overrideWorldTransform)
      : super(skinnable);

  @override
  void finalize(Map<String, Component> fileComponents) {
    final skinnable = component as PointsPath;
    var skinComponent = skinnable.children
        .firstWhere((child) => child is Skin, orElse: () => null);
    if (skinComponent is Skin) {
      final owt = overrideWorldTransform;
      skinComponent
        ..xx = owt[0]
        ..xy = owt[1]
        ..yx = owt[2]
        ..yy = owt[3]
        ..tx = owt[4]
        ..ty = owt[5];
    }
  }
}

class PathConverter extends NodeConverter {
  PathConverter(
      PointsPath component, RiveFile context, ContainerComponent maybeParent)
      : super(component, context, maybeParent);

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

    if (connectedBones is List) {
      for (var i = 0; i < connectedBones.length; i++) {
        final connection = connectedBones[i] as Map<String, Object>;
        final id = connection['id'];

        if (id is int) {
          final tConverter = TendonFinalizer(id.toString(), pathComponent)
            ..deserialize(connection);
          super.addFinalizer(tConverter);
        }
      }
    }

    if (owt is List) {
      final skinOWT = Mat2D();
      final sf = SkinFinalizer(pathComponent, skinOWT);
      super.addFinalizer(sf);
      skinOWT[0] = (owt[0] as num).toDouble();
      skinOWT[1] = (owt[1] as num).toDouble();
      skinOWT[2] = (owt[2] as num).toDouble();
      skinOWT[3] = (owt[3] as num).toDouble();
      skinOWT[4] = (owt[4] as num).toDouble();
      skinOWT[5] = (owt[5] as num).toDouble();
    }
  }
}
