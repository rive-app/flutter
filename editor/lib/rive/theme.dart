import 'dart:ui';
import 'package:flutter/widgets.dart';

/// Colors used in the Rive Theme
/// Define them as getters and keep them const
class RiveColors {
  const RiveColors();

  // Toolbar
  Color get toolbarBackground => const Color(0xFF3c3c3c);
  Color get toolbarButton => const Color(0xFF8C8C8C);
  Color get toolbarButtonBackGroundHover => const Color(0xFF444444);

  // Accents
  Color get accentBlue => const Color(0xFF57A5E0);
  Color get accentMagenta => const Color(0xFFFF5678);
  Color get accentDarkMagenta => const Color(0xFFD041AB);

  // Backgrounds
  Color get panelBackgroundLightGrey => const Color(0xFFF1F1F1);
  Color get panelBackgroundDarkGrey => const Color(0xFF323232);
  Color get popupBackground => const Color(0xFF111111);

  // Buttons
  Color get buttonLight => const Color(0xFFE3E3E3);
  Color get buttonDark => const Color(0xFF444444);
  Color get buttonNoHover => const Color(0xFF707070);
  Color get buttonHover => const Color(0xFFFFFFFF);
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
