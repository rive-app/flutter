import 'package:core/core.dart';
import 'package:meta/meta.dart';
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
    var old = _artboard;
    _artboard = value;
    // -> editor-only
    artboardId = value?.id;
    // <- editor-only
    artboardChanged(old, value);
  }

  @protected
  void artboardChanged(Artboard from, Artboard to) {
    from?.internalRemoveAnimation(this);
    to?.internalAddAnimation(this);
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
