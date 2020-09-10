import 'package:core/core.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/src/generated/animation/animation_base.dart';
export 'package:rive_core/src/generated/animation/animation_base.dart';

class Animation extends AnimationBase<RiveFile> {
  Artboard _artboard;
  Artboard get artboard => _artboard;
  set artboard(Artboard value) {
    if (_artboard == value) {
      return;
    }
    _artboard?.internalRemoveAnimation(this);
    _artboard = value;
    _artboard?.internalAddAnimation(this);
    // -> editor-only
    if (value != null) {
      artboardId = value.id;
    }
    // <- editor-only
  }

  @override
  void onAdded() {}

  @override
  void onAddedDirty() {
    // -> editor-only
    if (artboardId != null) {
      artboard = context?.resolve(artboardId);
      artboard?.whenRemoved(_remove);
    }
    // <- editor-only
  }

  @override
  void onRemoved() {
    artboard = null;
  }

  // -> editor-only
  void _remove() {
    context.removeObject(this);
  }

  @override
  void artboardIdChanged(Id from, Id to) {
    artboard = context?.resolve(to);
  }
  // <- editor-only

  @override
  void nameChanged(String from, String to) {}

  // -> editor-only
  @override
  void orderChanged(FractionalIndex from, FractionalIndex to) {
    artboard?.markAnimationOrderDirty();
  }
  // <- editor-only
}
