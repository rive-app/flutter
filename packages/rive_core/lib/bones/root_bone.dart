import 'package:rive_core/src/generated/bones/root_bone_base.dart';
export 'package:rive_core/src/generated/bones/root_bone_base.dart';

class RootBone extends RootBoneBase {
  // -> editor-only
  @override
  bool get canBoneCompensate => true;
  // <- editor-only

  @override
  void xChanged(double from, double to) {
    markTransformDirty();
  }

  @override
  void yChanged(double from, double to) {
    markTransformDirty();
  }

  // -> editor-only
  @override
  String get defaultName => 'Root Bone';
  // <- editor-only
}
