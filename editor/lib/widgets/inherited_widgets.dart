import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/icon_cache.dart';
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
/// RiveTheme.of(context).colors.buttonLight
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
