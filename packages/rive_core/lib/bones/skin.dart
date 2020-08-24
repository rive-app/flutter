import 'dart:typed_data';

import 'package:rive_core/bones/skeletal_component.dart';
import 'package:rive_core/bones/skinnable.dart';
import 'package:rive_core/bones/tendon.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/transform_components.dart';
import 'package:rive_core/shapes/path_vertex.dart';

import 'package:rive_core/src/generated/bones/skin_base.dart';
export 'package:rive_core/src/generated/bones/skin_base.dart';

/// Represents a skin deformation of either a Path or an Image Mesh connected to
/// a set of bones.
class Skin extends SkinBase {
  final List<Tendon> _tendons = [];
  List<Tendon> get tendons => _tendons;
  Float32List _boneTransforms;
  final Mat2D _worldTransform = Mat2D();

  @override
  bool validate() {
    return parent is Skinnable && super.validate();
  }

  @override
  void onDirty(int mask) {
    // When the skin is dirty the deformed skinnable will need to regenerate its
    // drawing commands.

    // TODO: rename path to topology/surface something common between path &
    // mesh.
    (parent as Skinnable).markSkinDirty();
  }

  @override
  void update(int dirt) {
    // Any dirt here indicates that the transforms needs to be rebuilt. This
    // should only be worldTransform from the bones (recursively passed down) or
    // ComponentDirt.path from the PointsPath (set explicitly).
    var size = (_tendons.length + 1) * 6;
    if (_boneTransforms == null || _boneTransforms.length != size) {
      _boneTransforms = Float32List(size);
      _boneTransforms[0] = 1;
      _boneTransforms[1] = 0;
      _boneTransforms[2] = 0;
      _boneTransforms[3] = 1;
      _boneTransforms[4] = 0;
      _boneTransforms[5] = 0;
    }

    var temp = Mat2D();
    var bidx = 6;
    for (final tendon in _tendons) {
      var boneWorld = tendon.bone.worldTransform;
      var wt = Mat2D.multiply(temp, boneWorld, tendon.inverseBind);
      var tc = TransformComponents();
      Mat2D.decompose(boneWorld, tc);
      _boneTransforms[bidx++] = wt[0];
      _boneTransforms[bidx++] = wt[1];
      _boneTransforms[bidx++] = wt[2];
      _boneTransforms[bidx++] = wt[3];
      _boneTransforms[bidx++] = wt[4];
      _boneTransforms[bidx++] = wt[5];
    }
  }

  void deform(List<PathVertex> vertices) {
    for (final vertex in vertices) {
      vertex.deform(_worldTransform, _boneTransforms);
    }
  }

  @override
  void onAdded() {
    super.onAdded();
    if (parent is Skinnable) {
      (parent as Skinnable).addSkin(this);
    }
  }

  @override
  void onRemoved() {
    if (parent is Skinnable) {
      (parent as Skinnable).removeSkin(this);
    }
    super.onRemoved();
  }

  @override
  void buildDependencies() {
    super.buildDependencies();
    // A skin depends on all its bones. N.B. that we don't depend on the parent
    // skinnable. The skinnable depends on us.
    for (final tendon in _tendons) {
      tendon.bone.addDependent(this);
    }

    // Have the skinnable depend on us. This works because we're not a node so
    // we have no dependency on our parent yet (which would cause a dependency
    // cycle).
    addDependent(parent);
  }

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    switch (child.coreType) {
      case TendonBase.typeKey:
        _tendons.add(child as Tendon);
        markRebuildDependencies();
        // -> editor-only
        (parent as Skinnable)?.internalTendonsChanged();
        // <- editor-only
        break;
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    switch (child.coreType) {
      case TendonBase.typeKey:
        _tendons.remove(child as Tendon);
        if (_tendons.isEmpty) {
          remove();
        } else {
          markRebuildDependencies();
        }
        // -> editor-only
        (parent as Skinnable)?.internalTendonsChanged();
        // <- editor-only

        break;
    }
  }

  // -> editor-only
  static Tendon bind(SkeletalComponent bone, Skinnable skinnable) {
    assert(bone != null);
    assert(bone.context != null,
        'the bone needs to already have been added to core');
    var core = bone.context;
    Tendon tendon;
    core.batchAdd(
      () {
        bone.calculateWorldTransform();
        var boneWorld = bone.worldTransform;

        tendon = core.addObject(
          Tendon()
            ..boneId = bone.id
            ..xx = boneWorld[0]
            ..xy = boneWorld[1]
            ..yx = boneWorld[2]
            ..yy = boneWorld[3]
            ..tx = boneWorld[4]
            ..ty = boneWorld[5],
        );
        var skinComponent = skinnable.children
            .firstWhere((child) => child is Skin, orElse: () => null);
        Skin skin;
        if (skinComponent != null) {
          skin = skinComponent as Skin;
          if (skin.tendons.any((tendon) => tendon.bone == bone)) {
            return null;
          }
        } else {
          skin = core.addObject(Skin());
          skinnable.appendChild(skin);
          skinnable.initWeights();

          // Store the world transform the skinnable was at when it was bound.
          var bindWorld = skinnable.worldTransform;
          skin.xx = bindWorld[0];
          skin.xy = bindWorld[1];
          skin.yx = bindWorld[2];
          skin.yy = bindWorld[3];
          skin.tx = bindWorld[4];
          skin.ty = bindWorld[5];
        }

        skin.appendChild(tendon);
      },
    );
    return tendon;
  }
  // <- editor-only

  @override
  void txChanged(double from, double to) {
    _worldTransform[4] = to;
  }

  @override
  void tyChanged(double from, double to) {
    _worldTransform[5] = to;
  }

  @override
  void xxChanged(double from, double to) {
    _worldTransform[0] = to;
  }

  @override
  void xyChanged(double from, double to) {
    _worldTransform[1] = to;
  }

  @override
  void yxChanged(double from, double to) {
    _worldTransform[2] = to;
  }

  @override
  void yyChanged(double from, double to) {
    _worldTransform[3] = to;
  }
}
