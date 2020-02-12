import 'dart:ui';
import 'package:flutter/widgets.dart';

/// Colors used in the Rive Theme
/// Define them as getters and keep them const
class RiveColors {
  const RiveColors();

  // Accents
  Color get accentBlue => const Color(0xFF57A5E0);
  Color get accentMagenta => const Color(0xFFFF5678);
  Color get accentDarkMagenta => const Color(0xFFD041AB);

  // Backgrounds
  Color get panelBackgroundLightGrey => const Color(0xFFF1F1F1);
  Color get panelBackgroundDarkGrey => const Color(0xFF323232);
  Color get toolbarGray => const Color(0xFF3c3c3c);
  Color get popupBackground => const Color(0xFF111111);

  // Buttons
  Color get buttonLight => const Color(0xFFE3E3E3);
  Color get buttonDark => const Color(0xFF444444);
}

/// TextStyles used in the Rive Theme
/// Define them as getters and keep them const
class TextStyles {
  const TextStyles();

  // Default style
  TextStyle get basic =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);

  // Inspector
  TextStyle get inspectorPropertyLabel =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);
  TextStyle get inspectorPropertySubLabel =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 11);
  TextStyle get inspectorPropertyValue =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);
  TextStyle get inspectorSectionHeader =>
      const TextStyle(fontFamily: 'Roboto-Medium', fontSize: 11);
  TextStyle get inspectorButton =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);
}

/// Gradients used in the Rive Theme
/// Define them as getters and keep them const
class Gradients {
  const Gradients();

  Gradient get magenta => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF5678), Color(0xFFD041AB)],
      );
}

/// Holds instances of various sub theme classes
/// This is used by the RiveTheme InheritedWidget
class RiveThemeData {
  const RiveThemeData();

  RiveColors get colors => const RiveColors();
  Gradients get gradients => const Gradients();
  TextStyles get textStyles => const TextStyles();
}

/// Inherited widget that will pass the theme down the tree
/// Too access the theme data anywhere in a Flutter context, use:
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
