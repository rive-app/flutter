import 'dart:ui';
import 'package:flutter/widgets.dart';

/// Colors used in the Rive Theme
/// Define them as getters and keep them const
class RiveColors {
  factory RiveColors() {
    return _instance;
  }
  const RiveColors._();
  static const RiveColors _instance = RiveColors._();

  // Toolbar
  Color get toolbarBackground => const Color(0xFF3c3c3c);
  Color get toolbarButton => const Color(0xFF8C8C8C);
  Color get toolbarButtonBackGroundHover => const Color(0xFF444444);

  // Popups
  Color get separator => const Color(0xFF262626);

  // Stage
  Color get toolTip => const Color(0x7F000000);

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

  Color get cursorGreen => const Color(0xFF16E6B3);
  Color get cursorRed => const Color(0xFFFF929F);
  Color get cursoYellow => const Color(0xFFFFF1BE);
  Color get cursorBlue => const Color(0xFF57A5E0);
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
  factory RiveThemeData() {
    return _instance;
  }
  const RiveThemeData._();
  static const RiveThemeData _instance = RiveThemeData._();

  RiveColors get colors => RiveColors();
  Gradients get gradients => const Gradients();
  TextStyles get textStyles => const TextStyles();
}
