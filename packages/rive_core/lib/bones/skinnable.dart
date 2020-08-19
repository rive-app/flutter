import 'package:rive_core/bones/skin.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/event.dart';

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
  // <- editor-only

  // These come in when Skinnable is mixedin/implemented with a
  // ContainerComponent (which is a requirement).
  ContainerChildren get children;
  void appendChild(Component child);

  // ignore: use_setters_to_change_properties
  void addSkin(Skin skin) {
    // Notify old skin/maybe support multiple skins in the future?
    _skin = skin;
    skinChanged.notify();
  }

  void removeSkin(Skin skin) {
    if (_skin == skin) {
      _skin = null;
      skinChanged.notify();
    }
  }
}
