import 'package:core/core.dart';
import 'package:core/id.dart';
import 'package:rive_core/bones/skeletal_component.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/src/generated/bones/tendon_base.dart';
export 'package:rive_core/src/generated/bones/tendon_base.dart';

class Tendon extends TendonBase {
  final Mat2D _bind = Mat2D();
  Mat2D _inverseBind;
  SkeletalComponent _bone;
  SkeletalComponent get bone => _bone;

  Mat2D get inverseBind {
    if (_inverseBind == null) {
      _inverseBind = Mat2D();
      Mat2D.invert(_inverseBind, _bind);
    }
    return _inverseBind;
  }

  // -> editor-only
  @override
  String get name => _bone?.name;

  @override
  set name(String value) => _bone?.name = value;

  @override
  Core eventDelegateFor(int propertyKey) {
    switch (propertyKey) {
      case ComponentBase.namePropertyKey:
        return _bone;
      default:
        return this;
    }
  }

  @override
  bool validate() {
    return _bone != null && super.validate();
  }
  // <- editor-only

  @override
  void boneIdChanged(Id from, Id to) {
    // This never happens, or at least it should only happen prior to an
    // onAddedDirty call.
  }

  @override
  void onAddedDirty() {
    super.onAddedDirty();
    if (boneId != null) {
      _bone = context?.resolve(boneId);
    }
  }

  @override
  void update(int dirt) {}

  @override
  void txChanged(double from, double to) {
    _bind[4] = to;
    _inverseBind = null;
  }

  @override
  void tyChanged(double from, double to) {
    _bind[5] = to;
    _inverseBind = null;
  }

  @override
  void xxChanged(double from, double to) {
    _bind[0] = to;
    _inverseBind = null;
  }

  @override
  void xyChanged(double from, double to) {
    _bind[1] = to;
    _inverseBind = null;
  }

  @override
  void yxChanged(double from, double to) {
    _bind[2] = to;
    _inverseBind = null;
  }

  @override
  void yyChanged(double from, double to) {
    _bind[3] = to;
    _inverseBind = null;
  }
}
