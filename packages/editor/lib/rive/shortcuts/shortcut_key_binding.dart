import 'dart:collection';

import 'package:flutter/services.dart';

import 'shortcut_actions.dart';
import 'shortcut_keys.dart';

/// A shortcut comprised of a set of keys that map to an action.
class Shortcut {
  final ShortcutAction action;
  final Set<ShortcutKey> keys;
  bool strictMatch = false;

  Shortcut(this.action, this.keys);
}

class ShortcutKeyBinding {
  final HashMap<PhysicalKeyboardKey, List<Shortcut>> _finalKeyToShortcuts =
      HashMap<PhysicalKeyboardKey, List<Shortcut>>();

  final HashMap<ShortcutAction, List<ShortcutKey>> _keysLookup =
      HashMap<ShortcutAction, List<ShortcutKey>>();

  /// Instance a key binding with a specific set of shortcuts that map
  ShortcutKeyBinding(List<Shortcut> shortcuts) {
    for (final shortcut in shortcuts) {
      (_keysLookup[shortcut.action] ??= []).addAll(shortcut.keys);

      var physicalKeys = keyToPhysical[shortcut.keys.last];
      for (final key in physicalKeys) {
        var list = _finalKeyToShortcuts[key] ??= [];
        list.add(shortcut);
      }

      // See if the binding needs to be strict, meaning that all keys must be
      // pressed. This is necessary as in the web the metakey hides when other
      // keys are released. This causes Flutter to assume those keys are still
      // pressed and send them again.

      // First check only if this binding includes the meta key. Similarly check
      // only other bindings that have meta.

      if (shortcut.keys.length > 1 &&
          shortcut.keys.contains(ShortcutKey.systemCmd)) {
        for (final otherShortcut in shortcuts) {
          if (otherShortcut == shortcut) {
            continue;
          }

          if (otherShortcut.keys.length > shortcut.keys.length &&
              otherShortcut.keys.intersection(shortcut.keys).length ==
                  shortcut.keys.length) {
            shortcut.strictMatch = true;
            break;
          }
        }
      }
    }
  }

  /// Find an action triggered by a specific set of keys.
  Set<ShortcutAction> lookupAction(
    List<PhysicalKeyboardKey> keys,
    PhysicalKeyboardKey lastPressed,
  ) {
    assert(
        keys.contains(lastPressed),
        'lastPressed must be in keys, it just helps us figure out what the '
        'critical key is');
    var actions = <ShortcutAction>{};
    if (keys.isEmpty) {
      // Nothing is pressed, early out...
      return actions;
    }

    var pressedKeySet = keys.toSet();
    var shortcuts = _finalKeyToShortcuts[lastPressed];
    if (shortcuts != null) {
      outerLoop:
      for (final shortcut in shortcuts) {
        if (shortcut.strictMatch &&
            shortcut.keys.length != pressedKeySet.length) {
          continue;
        }
        for (final key in shortcut.keys) {
          var physicalKeys = keyToPhysical[key];
          if (physicalKeys.intersection(pressedKeySet).isEmpty) {
            continue outerLoop;
          }
        }
        // this shortcut was triggered
        actions.add(shortcut.action);
      }
    }
    return actions;
  }

  /// Get the list of keys that trigger a specific action.
  List<ShortcutKey> lookupKeys(ShortcutAction action) => _keysLookup[action];

  /// Get the name of the key combo for an action, useful to show which keys to
  /// press for specific actions in the UI.
  String lookupKeysLabel(ShortcutAction action) {
    var keys = lookupKeys(action);
    if (keys == null) {
      return "???";
    }
    var name = StringBuffer();
    for (int i = 0; i < keys.length; i++) {
      if (i != 0) {
        name.write(' ');
      }
      name.write(keyname(keys[i]));
    }
    return name.toString();
  }
}
