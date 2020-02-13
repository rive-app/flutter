import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/shortcuts/default_key_binding.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_key_binding.dart';
import 'package:rive_editor/rive/theme.dart';

/// Inherited widget that will pass the theme down the tree
/// To access the theme data anywhere in a Flutter context, use:
///
/// RiveTheme.of(context).colors.buttonLight
///
class RiveTheme extends InheritedWidget {
  const RiveTheme({
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  RiveThemeData get theme => const RiveThemeData();

  static RiveThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RiveTheme>().theme;
  }

  @override
  bool updateShouldNotify(RiveTheme old) => theme != old.theme;
}

/// Inherited widget that will pass the theme down the tree
/// To access the theme data anywhere in a Flutter context, use:
///
/// IconCache.of(context).load('tool-add');
///
class IconCache extends InheritedWidget {
  const IconCache({
    @required this.cache,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final RiveIconCache cache;

  static RiveIconCache of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<IconCache>().cache;
  }

  @override
  bool updateShouldNotify(IconCache old) => cache != old.cache;
}

/// Inherited widget that will pass the shortcut key bindings down the tree
/// To access the theme data anywhere in a Flutter context, use:
///
/// RiveTheme.of(context).colors.buttonLight
///
class ShortcutBindings extends InheritedWidget {
  const ShortcutBindings({
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  ShortcutKeyBinding get bindings => defaultKeyBinding;

  static ShortcutKeyBinding of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ShortcutBindings>()
        .bindings;
  }

  @override
  bool updateShouldNotify(ShortcutBindings old) => bindings != old.bindings;
}
