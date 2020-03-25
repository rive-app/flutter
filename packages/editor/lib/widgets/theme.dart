import 'dart:ui';
import 'package:flutter/widgets.dart';

// General colors
const lightGrey = Color(0xFF8C8C8C);
const white = Color(0xFFFFFFFF);
const red = Color(0xFFFF5678);
const purple = Color(0xFFD041AB);

/// Colors used in the Rive Theme
/// Define them as getters and keep them const
class RiveColors {
  factory RiveColors() {
    return _instance;
  }
  const RiveColors._();
  static const RiveColors _instance = RiveColors._();

  // Tabs
  Color get tabText => lightGrey;
  Color get tabBackground => const Color(0xFF323232);
  Color get tabTextSelected => const Color(0xFFFDFDFD);
  Color get tabBackgroundSelected => const Color(0xFF3c3c3c);
  Color get tabBackgroundHovered => const Color(0xFF363636);

  Color get tabRiveText => lightGrey;
  Color get tabRiveBackground => const Color(0xFF323232);
  Color get tabRiveTextSelected => const Color(0xFF323232);
  Color get tabRiveBackgroundSelected => const Color(0xFFF1F1F1);

  // Toolbar
  Color get toolbarBackground => const Color(0xFF3c3c3c);
  Color get toolbarButton => lightGrey;
  Color get toolbarButtonSelected => const Color(0xFF57A5E0);
  Color get toolbarButtonHover => white;
  Color get toolbarButtonBackGroundHover => const Color(0xFF444444);
  Color get toolbarButtonBackGroundPressed => const Color(0xFF262626);

  // Popups
  Color get separator => const Color(0xFF262626);
  Color get separatorActive => const Color(0xFFAEAEAE);
  Color get popupIconSelected => const Color(0xFF57A5E0);
  Color get popupIcon => const Color(0xFF707070);
  Color get popupIconHover => white;

  // Stage
  Color get toolTip => const Color(0x7F000000);
  Color get toolTipText => white;
  Color get shapeBounds => const Color(0xFF000000);

  // Accents
  Color get accentBlue => const Color(0xFF57A5E0);
  Color get accentMagenta => const Color(0xFFFF5678);
  Color get accentDarkMagenta => const Color(0xFFD041AB);

  // Backgrounds
  Color get panelBackgroundLightGrey => const Color(0xFFF1F1F1);
  Color get panelBackgroundDarkGrey => const Color(0xFF323232);
  Color get stageBackground => const Color(0xFF1D1D1D);
  Color get popupBackground => const Color(0xFFF1F1F1);

  // Buttons
  Color get buttonLight => const Color(0xFFE3E3E3);
  Color get buttonDark => const Color(0xFF444444);
  Color get buttonNoHover => const Color(0xFF707070);
  Color get buttonHover => white;

  // Cursors
  Color get cursorGreen => const Color(0xFF16E6B3);
  Color get cursorRed => const Color(0xFFFF929F);
  Color get cursoYellow => const Color(0xFFFFF1BE);
  Color get cursorBlue => const Color(0xFF57A5E0);

  Color get animateToggleButton => const Color(0xFF444444);
  Color get inactiveText => const Color(0xFF888888);
  Color get activeText => white;

  // Files
  Color get fileBackgroundDarkGrey => const Color(0xFF666666);
  Color get fileBackgroundLightGrey => const Color(0xFFF1F1F1);
  Color get fileSelectedBlue => const Color(0xFF57A5E0);
  Color get fileLineGrey => const Color(0xFFD8D8D8);
  Color get fileTextLightGrey => lightGrey;
  Color get fileSelectedFolderIcon => white;
  Color get fileUnselectedFolderIcon => const Color(0xFFA9A9A9);
  Color get fileIconColor => const Color(0xFFA9A9A9);
  Color get fileBorder => const Color(0xFFD8D8D8);
  Color get fileSearchBorder => const Color(0xFFE3E3E3);
  Color get fileSearchIcon => const Color(0xFF999999);

  // Common
  Color get commonDarkGrey => const Color(0xFF333333);
  Color get commonButtonColor => const Color(0x19000000);
  Color get commonButtonTextColor => const Color(0xFF888888);
  Color get commonButtonTextColorDark => const Color(0xFF666666);

  // Inspector
  Color get inspectorTextColor => const Color(0xFF8C8C8C);
  Color get inspectorSeparator => const Color(0xFF444444);

  // TextField
  Color get textSelection => lightGrey;
  Color get inputUnderline => const Color(0xFFCCCCCC);
  Color get input => const Color(0xFFBBBBBB);
}

/// TextStyles used in the Rive Theme
/// Define them as getters and keep them const
class TextStyles {
  const TextStyles();

  // Default style
  TextStyle get basic =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);

  // Hierarchy panel
  TextStyle get hierarchyTabActive => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFFAAAAAA), fontSize: 11);

  TextStyle get hierarchyTabInactive => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFF656565), fontSize: 11);

  TextStyle get hierarchyTabHovered => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFF888888), fontSize: 11);

  // Inspector panel
  TextStyle get inspectorPropertyLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: lightGrey, fontSize: 13);

  TextStyle get inspectorPropertySubLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: lightGrey, fontSize: 11);

  TextStyle get inspectorPropertyValue => const TextStyle(
      fontFamily: 'Roboto-Light', color: Color(0xFFE3E3E3), fontSize: 12.5);

  TextStyle get inspectorSectionHeader => const TextStyle(
      fontFamily: 'Roboto-Medium', fontSize: 11, color: lightGrey);

  TextStyle get inspectorButton =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);

  TextStyle get inspectorWhiteLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFFC8C8C8), fontSize: 13);

  // Popup Menus
  TextStyle get popupHovered =>
      const TextStyle(fontFamily: 'Roboto-Light', color: white, fontSize: 13);

  TextStyle get popupText => const TextStyle(
      fontFamily: 'Roboto-Light', color: lightGrey, fontSize: 13);

  TextStyle get popupShortcutText => const TextStyle(
      fontFamily: 'Roboto-Light', color: Color(0xFF666666), fontSize: 13);

  TextStyle get tooltipText => const TextStyle(
      fontFamily: 'Roboto-Light', color: Color(0xFFCCCCCC), fontSize: 13);

  TextStyle get tooltipDisclaimer => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF888888),
      fontSize: 13,
      fontWeight: FontWeight.w100);

  TextStyle get tooltipHyperlink => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF333333),
      fontSize: 13,
      fontWeight: FontWeight.w300,
      decoration: TextDecoration.underline);

  TextStyle get tooltipHyperlinkHovered => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF57A5E0),
      fontSize: 13,
      fontWeight: FontWeight.w300,
      decoration: TextDecoration.underline);

  // Files
  TextStyle get fileBlueText => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF57A5E0),
        fontSize: 13,
      );
  TextStyle get fileGreyTextSmall => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF333333),
        fontSize: 11,
        fontWeight: FontWeight.w300,
      );
  TextStyle get fileGreyTextLarge => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF333333),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );
  TextStyle get fileLightGreyText => const TextStyle(
      fontFamily: 'Roboto-Medium',
      color: Color(0xFF666666),
      fontSize: 13,
      fontWeight: FontWeight.w300);

  TextStyle get fileSearchText => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFF999999), fontSize: 13);

  // Common
  TextStyle get greyText => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFF333333), fontSize: 13);

  // Wizard TextField
  // Common
  TextStyle get textFieldInputHint => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFFBBBBBB), fontSize: 16);
}

/// Gradients used in the Rive Theme
/// Define them as getters and keep them const
class Gradients {
  const Gradients();

  Gradient get magenta => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          red,
          purple,
        ],
      );

  Gradient get redPurpleBottomCenter => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          red,
          purple,
        ],
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
