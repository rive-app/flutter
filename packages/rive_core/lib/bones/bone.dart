import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/bones/bone_base.dart';
export 'package:rive_core/src/generated/bones/bone_base.dart';

typedef bool BoneCallback(Bone bone);

class Bone extends BoneBase {
  // -> editor-only
  bool get canBoneCompensate => false;

  @override
  void compensate() {
    if (!canBoneCompensate) {
      return;
    }
    super.compensate();
  }

  @override
  String get defaultName {
    int boneIndex = 0;
    var parentBone = parent;
    while (parentBone is Bone) {
      boneIndex++;
      parentBone = parentBone.parent;
    }
    return 'Bone $boneIndex';
  }
  // <- editor-only

  @override
  void lengthChanged(double from, double to) {
    for (final child in children) {
      if (child.coreType == BoneBase.typeKey) {
        (child as Bone).markTransformDirty();
      }
    }
    // -> editor-only
    markBoundsChanged();
    // <- editor-only
  }

  // -> editor-only
  @override
  void markBoundsChanged() {
    super.markBoundsChanged();
    recomputeParentExpandableBounds();
  }

  @override
  void onRemoved() {
    recomputeParentExpandableBounds();
    super.onRemoved();
  }

  @override
  void updateWorldTransform() {
    super.updateWorldTransform();
    recomputeParentExpandableBounds();
  }
  // <- editor-only

  Bone get firstChildBone {
    for (final child in children) {
      if (child.coreType == BoneBase.typeKey) {
        return child as Bone;
      }
    }
    return null;
  }

  /// Iterate through the child bones. [BoneCallback] returns false if iteration
  /// can stop. Returns false if iteration stopped, true if it made it through
  /// the whole list.
  bool forEachBone(BoneCallback callback) {
    for (final child in children) {
      if (child.coreType == BoneBase.typeKey) {
        if (!callback(child as Bone)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  double get x => (parent as Bone).length;

  @override
  set x(double value) {
    throw UnsupportedError('not expected to set x on a bone.');
  }

  @override
  double get y => 0;

  @override
  set y(double value) {
    throw UnsupportedError('not expected to set y on a bone.');
  }

  // -> editor-only
  Vec2D get tipWorldTranslation => getTipWorldTranslation(worldTransform);

  Vec2D getTipWorldTranslation(Mat2D worldTransform) {
    var tip = Vec2D();
    Vec2D.transformMat2D(tip, Vec2D.fromValues(length, 0), worldTransform);
    return tip;
  }

  Mat2D get tipWorldTransform => getTipWorldTransform(worldTransform);

  Mat2D getTipWorldTransform(Mat2D worldTransform) => Mat2D.multiply(Mat2D(),
      worldTransform, Mat2D.fromTranslation(Vec2D.fromValues(length, 0)));

  // <- editor-only
}
