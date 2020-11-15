import 'package:peon_process/converters.dart';
import 'package:rive_core/bones/bone.dart';
import 'package:rive_core/bones/skin.dart';
import 'package:rive_core/bones/skinnable.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';

class BoneConverter extends TransformComponentConverter {
  BoneConverter(
    Bone component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super(component, context, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    final type = jsonData['type'];
    var length = jsonData['length'];

    if (type == 'rootBone') {
      length = 0;
    }
    final size = jsonData['size'];

    final bone = component as Bone;

    if (length is num) {
      bone.length = length.toDouble();
    }
  }
}

class SkinConverter extends ComponentConverter {
  SkinConverter(
      Skin component, RiveFile context, ContainerComponent maybeParent)
      : assert(maybeParent is Skinnable),
        super.init(component) {
    context.batchAdd(() {
      context.addObject(component);
      maybeParent.appendChild(component);
    });
  }
}
