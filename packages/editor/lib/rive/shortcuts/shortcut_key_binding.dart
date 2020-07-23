import 'dart:collection';

import 'shortcut_actions.dart';
import 'shortcut_keys.dart';

/// A shortcut comprised of a set of keys that map to an action.
class Shortcut {
  final ShortcutAction action;
  final Set<ShortcutKey> keys;

  Shortcut(this.action, this.keys);
}

class ShortcutKeyBinding {
  final HashMap<ShortcutKey, List<Shortcut>> _finalKeyToShortcuts =
      HashMap<ShortcutKey, List<Shortcut>>();

  final HashMap<ShortcutAction, List<ShortcutKey>> _keysLookup =
      HashMap<ShortcutAction, List<ShortcutKey>>();

  /// Instance a key binding with a specific set of shortcuts that map
  ShortcutKeyBinding(List<Shortcut> shortcuts) {
    for (final shortcut in shortcuts) {
      (_keysLookup[shortcut.action] ??= []).addAll(shortcut.keys);

      var list = _finalKeyToShortcuts[shortcut.keys.last] ??= [];
      list.add(shortcut);
    }

    _finalKeyToShortcuts.forEach((key, shortcuts) {
      // sort the list such that the shortcuts with most keys get priority (sort
      // desc).
      shortcuts.sort((a, b) => b.keys.length.compareTo(a.keys.length));
    });
  }

  /// Find an action triggered by a specific set of keys.
  Set<ShortcutAction> lookupAction(
    Iterable<ShortcutKey> keys,
    ShortcutKey lastPressed,
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
      Shortcut lastTriggered;
      for (final shortcut in shortcuts) {
        // Early out if some previous shortcut on this key just triggered and
        // contains more modifiers/keys. This prevents things like undo (cmd+z)
        // triggering when redo (cmd+shift+z) is pressed. This requires the
        // shortcuts to be sorted in desc modifier key length.
        if (lastTriggered != null &&
            lastTriggered.keys.length != shortcut.keys.length) {
          continue;
        }
        if (shortcut.keys.intersection(pressedKeySet).length !=
            shortcut.keys.length) {
          // if not all keys are pressed, then this action doesn't trigger
          continue;
        }
        // this shortcut was triggered

        actions.add((lastTriggered = shortcut).action);
      }
    }

    // Also iterate keys to find any HoldShortcutActions that may still be
    // pressed.
    for (final key in keys) {
      if (key == lastPressed) {
        continue;
      }
      shortcuts = _finalKeyToShortcuts[key];
      if (shortcuts != null) {
        for (final shortcut in shortcuts) {
          // If it's a hold and the keys are still pressed, make sure it's still
          // considered active.
          if (shortcut.action is HoldShortcutAction &&
              shortcut.keys.intersection(pressedKeySet).length ==
                  shortcut.keys.length) {
            actions.add(shortcut.action);
          }
        }
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
