import 'package:peon_process/converters.dart';
import 'package:rive_core/bones/bone.dart';
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
    
    print('This bone is a $type');
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
