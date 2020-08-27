import 'package:rive_core/bones/skin.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/mat2d.dart';

/// An abstraction to give a common interface to any container component that
/// can contain a skin to bind bones to.
abstract class Skinnable {
  Skin _skin;
  Skin get skin => _skin;
  // -> editor-only
  final Event skinChanged = Event();
  // Should be @internal when supported...
  void internalTendonsChanged() {
    skinChanged.notify();
  }

  // These come in when Skinnable is mixedin/implemented with a
  // ContainerComponent (which is a requirement). We only iterate the children
  // in the editor.
  ContainerChildren get children;
  // <- editor-only

  void appendChild(Component child);

  // ignore: use_setters_to_change_properties
  void addSkin(Skin skin) {
    assert(skin != null);
    // Notify old skin/maybe support multiple skins in the future?
    _skin = skin;
    // -> editor-only
    skinChanged.notify();
    // <- editor-only
    markSkinDirty();
  }

  void removeSkin(Skin skin) {
    if (_skin == skin) {
      _skin = null;
      // -> editor-only
      clearWeights();
      skinChanged.notify();
      // <- editor-only
      markSkinDirty();
    }
  }

  void markSkinDirty();

  // -> editor-only
  Mat2D get worldTransform;
  void initWeights();
  void clearWeights();
  // <- editor-only

}
