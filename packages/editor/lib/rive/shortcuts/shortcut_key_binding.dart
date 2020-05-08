import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:trotter/trotter.dart';

import 'shortcut_actions.dart';
import 'shortcut_keys.dart';


/// A shortcut comprised of a set of keys that map to an action.
class Shortcut {
  final ShortcutAction action;
  final List<ShortcutKey> keys;

  Shortcut(this.action, this.keys);
}

class ShortcutKeyBinding {
  final HashMap<PhysicalKeyboardKey, _ShortcutNode> _mapping =
      HashMap<PhysicalKeyboardKey, _ShortcutNode>();
  final HashMap<ShortcutAction, List<ShortcutKey>> _keysLookup =
      HashMap<ShortcutAction, List<ShortcutKey>>();

  /// Instance a key binding with a specific set of shortcuts that map
  ShortcutKeyBinding(List<Shortcut> shortcuts) {
    for (final entry in shortcuts) {
      var perms = Permutations(entry.keys.length, entry.keys);
      for (final v in perms()) {
        _build(_mapping, 0, v, entry.action);
      }

      _keysLookup[entry.action] = entry.keys;
    }
  }

  /// Find an action triggered by a specific set of keys.
  List<ShortcutAction> lookupAction(List<PhysicalKeyboardKey> keys) {
    var keymap = _mapping;
    for (int i = 0; i < keys.length && keymap != null; i++) {
      var key = keys[i];
      if (i == keys.length - 1) {
        return keymap[key]?.actions;
      } else {
        keymap = keymap[key]?.keys;
      }
    }
    return null;
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

  void _build(HashMap<PhysicalKeyboardKey, _ShortcutNode> keymap, int index,
      List<ShortcutKey> keys, ShortcutAction action) {
    var key = keys[index];
    var physical = keyToPhysical[key];
    for (final pk in physical) {
      var map = keymap[pk] ??= _ShortcutNode();
      if (index + 1 == keys.length) {
        map.addAction(action);
      } else {
        map.keys ??= HashMap<PhysicalKeyboardKey, _ShortcutNode>();
        _build(map.keys, index + 1, keys, action);
      }
    }
  }
}

/// Shortcut node in the graph of key permutations.
class _ShortcutNode {
  List<ShortcutAction> actions;
  HashMap<PhysicalKeyboardKey, _ShortcutNode> keys;

  void addAction(ShortcutAction action) {
    actions ??= [];
    actions.add(action);
  }
}