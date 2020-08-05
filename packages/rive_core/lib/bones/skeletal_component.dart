import 'package:rive_core/bones/root_bone.dart';
import 'package:rive_core/src/generated/bones/skeletal_component_base.dart';
export 'package:rive_core/src/generated/bones/skeletal_component_base.dart';

abstract class SkeletalComponent extends SkeletalComponentBase {
  // -> editor-only
  @override
  void compensate() {
    // Sanity check to make sure only root bones attempt compensation at
    // edit-time.
    assert(this is RootBone);
    super.compensate();
  }
  // <- editor-only
}
