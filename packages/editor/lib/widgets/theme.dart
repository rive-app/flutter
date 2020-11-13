import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:tree_widget/tree_style.dart';

import 'theme/theme_native.dart' if (dart.library.html) 'theme/theme_web.dart';

// General colors
const lightGrey = Color(0xFF8C8C8C);
const grey = Color(0xFF666666);
const darkGrey = Color(0xFF333333);
const white = Color(0xFFFFFFFF);
const black = Color(0xFF000000);
const red = Color(0xFFFF5678);
const magenta = Color(0xFFFF5777);
const purple = Color(0xFFD041AB);
const transparent = Color(0x00000000);
const transparent50 = Color(0x88FFFFFF);

const _darkTreeLines = Color(0x33FFFFFF);

/// Colors used in the Rive Theme
/// Define them as getters and keep them const
class RiveColors {
  factory RiveColors() => _instance;
  const RiveColors._();
  static const RiveColors _instance = RiveColors._();

  // Tabs
  Color get tabText => lightGrey;
  Color get text => grey;
  Color get tabBackground => const Color(0xFF323232);
  Color get tabTextSelected => const Color(0xFFFDFDFD);
  Color get tabBackgroundSelected => const Color(0xFF3c3c3c);
  Color get tabBackgroundHovered => const Color(0xFF363636);

  Color get tabRiveText => lightGrey;
  Color get tabRiveBackground => const Color(0xFF323232);
  Color get tabRiveTextSelected => const Color(0xFF323232);
  Color get tabRiveBackgroundSelected => const Color(0xFFF1F1F1);
  Color get tabRiveSeparator => const Color(0xFF555555);

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
  Color get globalMessageBackground => const Color(0xFF111111);
  Color get globalMessageBorder => const Color(0xFF3E3E3E);
  Color get stageBackground => const Color(0xFF1D1D1D);
  Color get popupBackground => const Color(0xFFF1F1F1);

  // Buttons
  Color get buttonLight => const Color(0xFFE3E3E3);
  Color get textButtonLight => const Color(0xFFF1F1F1);
  Color get buttonLightHover => const Color(0xFFDEDEDE);
  Color get textButtonLightHover => const Color(0xFFDEDEDE);
  Color get buttonLightText => const Color(0xFF666666);
  Color get buttonLightDisabled => const Color(0xFFF8F8F8);
  Color get buttonLightTextDisabled => const Color(0xFFD9D9D9);

  Color get iconButtonLightIcon => const Color(0xFF888888);
  Color get iconButtonLightDisabled => const Color(0xFFEBEBEB);
  Color get iconButtonLightTextDisabled => const Color(0xFFCECECE);
  Color get iconButtonLightIconDisabled => const Color(0xFFD7D7D7);

  Color get buttonDark => const Color(0xFF444444);
  Color get textButtonDark => const Color(0xFF333333);
  Color get buttonDarkText => white;
  Color get buttonDarkDisabled => const Color(0xFFCCCCCC);
  Color get buttonDarkTextHovered => white;
  Color get buttonDarkDisabledText => white;

  Color get buttonNoHover => const Color(0xFF707070);
  Color get buttonHover => white;

  // Cursors
  Color get cursorGreen => const Color(0xFF16E6B3);
  Color get cursorRed => const Color(0xFFFF929F);
  Color get cursoYellow => const Color(0xFFFFF1BE);
  Color get cursorBlue => const Color(0xFF57A5E0);

  Color get animateToggleButton => const Color(0xFF444444);
  Color get inactiveText => const Color(0xFF888888);
  Color get inactiveButtonText => const Color(0xFFB3B3B3);
  Color get activeText => white;

  // Files
  Color get fileBackgroundDarkGrey => const Color(0xFF666666);
  Color get fileBackgroundLightGrey => const Color(0xFFF1F1F1);
  Color get fileSelectedBlue => const Color(0xFF57A5E0);
  Color get fileLineGrey => const Color(0xFFD8D8D8);
  Color get fileTreeText => const Color(0xFF666666);
  Color get fileSelectedFolderIcon => white;
  Color get fileUnselectedFolderIcon => const Color(0xFFA9A9A9);
  Color get fileIconColor => const Color(0xFFA9A9A9);
  Color get fileBorder => const Color(0xFFD8D8D8);
  Color get fileTreeBackgroundHover => const Color(0xFFE3E3E3);
  Color get fileSearchBorder => const Color(0xFFE3E3E3);
  Color get fileSearchIcon => const Color(0xFF999999);
  Color get filesTreeStroke => const Color(0xFFCCCCCC);
  Color get fileBrowserBackground => white;

  Color get treeIconIdle => const Color(0xFFA9A9A9);
  Color get treeIconHovered => const Color(0xFF666666);
  Color get treeIconSelectedIdle => const Color(0xFFD5E8F7);
  Color get treeIconSelectedHovered => white;

  // Common
  Color get commonLightGrey => const Color(0xFF888888);
  Color get commonDarkGrey => const Color(0xFF333333);
  Color get commonButtonColor => const Color(0x19000000);
  Color get commonButtonTextColor => commonLightGrey;
  Color get commonButtonTextColorDark => const Color(0xFF666666);
  Color get commonButtonInactiveGrey => const Color(0xFFE7E7E7);

  // Inspector
  Color get inspectorTextColor => const Color(0xFF8C8C8C);
  Color get inspectorSeparator => const Color(0xFF444444);

  // TextField
  Color get textSelection => lightGrey;
  Color get selectedText => white;
  Color get inputUnderline => const Color(0xFFCCCCCC);
  Color get input => const Color(0xFFBBBBBB);

  // Tree
  Color get darkTreeLines => _darkTreeLines;

  // Hierarchy
  Color get editorTreeHover => const Color(0x20AAAAAA);
  Color get animationSelected => const Color(0x24888888);
  Color get hierarchyText => lightGrey;

  Color get shadow25 => const Color(0x44000000);
  Color get black30 => const Color(0x4D000000);

  Color get lightTreeLines => const Color(0x27666666);
  Color get selectedTreeLines => const Color(0xFF79B7E6);
  Color get toggleBackground => const Color(0xFF252525);
  Color get toggleInactiveBackground => const Color(0xFFF1F1F1);
  Color get toggleForeground => white;
  Color get toggleForegroundDisabled => const Color(0xFF444444);

  Color get treeHover => const Color(0x32AAAAAA);

  // Mode button
  Color get modeBackground => const Color(0xFF2F2F2F);
  Color get modeForeground => const Color(0xFF444444);

  // Animation panel
  Color get animationPanelBackground => const Color(0xFF282828);
  Color get timelineViewportControlsBackground => const Color(0xFF1F1F1F);
  Color get timelineViewportControlsGrabber => const Color(0xFF33A7FF);
  Color get timelineViewportControlsTrack => const Color(0xFF4C4C4C);
  Color get timelineBackground => const Color(0xFF232323);
  Color get timelineLine => const Color(0x0FFFFFFF);
  Color get timelineUnderline => const Color(0xFF1E1E1E);
  Color get key => const Color(0xFF57A5E0);
  Color get allKey => const Color(0xFF8A8A8A);
  Color get keySelection => const Color(0xFFFFFFFF);
  Color get keyLine => const Color(0xBF57A5E0);
  Color get keyMarqueeFill => const Color(0x3433A7FF);
  Color get keyMarqueeStroke => const Color(0xFF33A7FF);
  Color get keyStateEmpty => const Color(0xFF8C8C8C);
  Color get workAreaBackground => const Color(0xFF2C2C2C);
  Color get workAreaDelineator => const Color(0xFF111111);
  Color get timelineButtonBackGroundHover => const Color(0xFF323232);
  Color get interpolationUnderline => const Color(0xFF181818);
  Color get interpolationCurveBackground => const Color(0xFF303030);
  Color get interpolationPreviewSeparator => const Color(0xFF3C3C3C);
  Color get interpolationControlHandleIn => const Color(0xFF29BB9C);
  Color get interpolationControlHandleOut => const Color(0xFF33A7FF);
  Color get timelineBackgroundHover => const Color(0x20646464);
  Color get timelineBackgroundSelected => const Color(0x20646464);
  Color get timelineTreeBackgroundHover => const Color(0x20646464);
  Color get timelineTreeBackgroundSelected => const Color(0x20646464);

  // Inspector panel pill button
  Color get inspectorPillBackground => buttonDark;
  Color get inspectorPillDisabledBackground => textButtonDark;
  Color get inspectorPillHover => const Color(0xFF555555);
  Color get inspectorPillText => const Color(0xFFB2B2B2);
  Color get inspectorPillDisabledText => buttonDarkDisabledText;
  Color get inspectorPillIcon => lightGrey;

  Color get inspectorWarning => const Color(0xFFFFD76B);

  Color get vertexIcon => const Color(0xFF848484);
  Color get vertexIconHover => white;

  // Login colors
  Color get loginLogo => const Color(0xFF000000);

  // Revision Panel colors
  Color get selectedRevision => const Color(0xFF3E3E3E);
  Color get hoveredRevision => inspectorPillBackground;

  Color get getTransparent50 => transparent50;
  Color get getTransparent => transparent;
  Color get getBlack => black;
  Color get getWhite => white;

  // Snapping colors
  Color get snappingLine => magenta;

  // Plans
  Color get errorText => magenta;

  // Bone Colors
  List<Color> get boundBones => const [
        Color.fromARGB(255, 109, 145, 255),
        Color.fromARGB(255, 144, 90, 238),
        Color.fromARGB(255, 255, 106, 147),
        Color.fromARGB(255, 255, 214, 106),
        Color.fromARGB(255, 104, 254, 217),
        Color.fromARGB(255, 212, 222, 255),
        Color.fromARGB(255, 209, 183, 255),
        Color.fromARGB(255, 255, 153, 182),
        Color.fromARGB(255, 255, 238, 195),
        Color.fromARGB(255, 201, 255, 241),
        Color.fromARGB(255, 18, 76, 255),
        Color.fromARGB(255, 255, 0, 255),
        Color.fromARGB(255, 244, 46, 100),
        Color.fromARGB(255, 251, 188, 20),
        Color.fromARGB(255, 0, 190, 143),
      ];

  // Error page colors
  Color get errorBackground => const Color(0xFF282828);
}

/// TextStyles used in the Rive Theme
/// Define them as getters and keep them const
class TextStyles {
  const TextStyles();

  // Default style
  TextStyle get basic =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);

  TextStyle get hierarchyName => const TextStyle(
      fontFamily: 'Roboto-Medium', fontSize: 13, color: Color(0xFFAAAAAA));

  // TODO: Used in the settings pages, need to rename this...
  TextStyle get hierarchyTabHovered => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFF888888), fontSize: 11);

  // Inspector panel
  TextStyle get inspectorPropertyLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: lightGrey, fontSize: 13);

  TextStyle get inspectorPropertySubLabel => const TextStyle(
        fontFamily: 'Roboto-Regular', color: lightGrey, fontSize: 11,
        // need a tiny bit of kerning inwards here to allow sublabels to not
        // spill
        letterSpacing: -0.1,
      );

  TextStyle get inspectorPropertyValue => const TextStyle(
      fontFamily: 'Roboto-Light', color: Color(0xFFE3E3E3), fontSize: 12.5);

  TextStyle get inspectorSectionHeader => const TextStyle(
        fontFamily: 'Roboto-Medium',
        fontSize: 13,
        color: Color(0xFFAAAAAA),
        height: 1,
      );

  TextStyle get inspectorWarning => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFFFFD76B), fontSize: 13);

  TextStyle get animationsHeader => const TextStyle(
      fontFamily: 'Roboto-Medium', fontSize: 11, color: lightGrey, height: 1);

  TextStyle get inspectorButton =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);

  TextStyle get inspectorWhiteLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFFC8C8C8), fontSize: 13);

  TextStyle get inspectorDescription => const TextStyle(
      fontFamily: 'Roboto-Regular', color: lightGrey, fontSize: 13);
  // Popup Menus
  TextStyle get popupHovered =>
      const TextStyle(fontFamily: 'Roboto-Light', color: white, fontSize: 13);

  TextStyle get popupText => const TextStyle(
      fontFamily: 'Roboto-Light', color: lightGrey, fontSize: 13);

  TextStyle get popupShortcutText => const TextStyle(
      fontFamily: 'Roboto-Light', color: Color(0xFF666666), fontSize: 13);

  TextStyle get tooltipText => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFFCCCCCC),
      fontSize: 13,
      height: 1.61);

  TextStyle get tooltipDisclaimer => const TextStyle(
        fontFamily: 'Roboto-Light',
        color: Color(0xFF888888),
        fontSize: 13,
      );

  TextStyle get tooltipBold => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF333333),
      fontSize: 13,
      fontWeight: FontWeight.bold);

  TextStyle get tooltipHyperlink => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF333333),
      fontSize: 13,
      decoration: TextDecoration.underline);

  TextStyle get tooltipHyperlinkHovered => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF57A5E0),
      fontSize: 13,
      decoration: TextDecoration.underline);

  TextStyle get hyperLinkSubtext => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF333333),
      fontSize: 13,
      letterSpacing: 0,
      decoration: TextDecoration.underline);

  TextStyle get buttonTextStyle => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF888888),
        fontSize: 13,
      );

  TextStyle get loginText => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF888888),
      fontSize: 13,
      letterSpacing: 0);

  // Notifications
  TextStyle get notificationTitle => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF333333),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      );

  TextStyle get notificationText => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF666666),
        height: 1.6,
        fontSize: 13,
      );

  TextStyle get planText => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF666666),
        height: 1.6,
        fontSize: 13,
      );

  TextStyle get planDarkText =>
      planText.copyWith(color: const Color(0xFF333333));

  TextStyle get notificationHeader => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF888888),
        fontSize: 16,
      );

  TextStyle get notificationHeaderSelected => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF333333),
        fontSize: 16,
      );

  // Files
  TextStyle get fileBlueText => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF57A5E0),
        fontSize: 13,
      );
  TextStyle get fileGreyTextSmall => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF333333),
        fontSize: 11,
        fontWeight: FontWeight.w300,
      );
  TextStyle get fileGreyTextLarge => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF333333),
      fontSize: 16,
      fontWeight: FontWeight.w400);
  TextStyle get fileLightGreyText => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF666666),
      fontSize: 13,
      fontWeight: FontWeight.w300);
  TextStyle get fileWhiteText => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: white,
      fontSize: 13,
      fontWeight: FontWeight.w300);
  TextStyle get fileBlueTextLight => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF57A5E0),
      fontSize: 13,
      fontWeight: FontWeight.w300);

  TextStyle get fileSearchText => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFF999999), fontSize: 13);

  TextStyle get fileSearchTextBold => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: black,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  TextStyle get fileBrowserText => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF888888),
      height: 1.615,
      fontSize: 13,
      letterSpacing: 0);

  // Common
  TextStyle get greyText => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFF333333), fontSize: 13);

  // TextField
  // Common
  TextStyle get textFieldInputHint => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFFBBBBBB), fontSize: 16);

  TextStyle get textFieldInputValidationError =>
      const TextStyle(fontFamily: 'Roboto-Medium', color: red, fontSize: 13);

  TextStyle get buttonUnderline => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF333333),
      fontSize: 12,
      height: 1.6,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.underline);

  TextStyle get regularText => const TextStyle(
        fontFamily: 'Roboto-Regular',
        fontSize: 13,
        height: 1.15,
        fontWeight: FontWeight.normal,
      );

  TextStyle get paragraphText => const TextStyle(
      fontFamily: 'Roboto-Light',
      fontSize: 13,
      height: 1.6,
      fontWeight: FontWeight.w300,
      color: grey);

  TextStyle get paragraphTextHyperlink => paragraphText.copyWith(
        color: darkGrey,
        decoration: TextDecoration.underline,
      );

  TextStyle get errorText =>
      const TextStyle(color: white, fontFamily: 'Roboto-Regular', fontSize: 13);

  TextStyle get redErrorText => const TextStyle(
      color: magenta, fontFamily: 'Roboto-Regular', fontSize: 13);

  // Mode button
  TextStyle get modeLabel => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF888888),
        fontSize: 13,
      );
  TextStyle get modeLabelSelected => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFFFFFFFF),
        fontSize: 13,
      );

  // Tree
  TextStyle get treeDragItem => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: white,
      fontSize: 13,
      decoration: TextDecoration.none);

  // Timeline
  TextStyle get timelineTicks => const TextStyle(
      fontFamily: 'Roboto-Regular', color: lightGrey, fontSize: 11);

  TextStyle get animationSubLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFF686868), fontSize: 13);

  TextStyle get vertexTypeLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFF989898), fontSize: 12.5);
  TextStyle get vertexTypeSelected => const TextStyle(
      fontFamily: 'Roboto-Regular', color: white, fontSize: 12.5);

  // Get started
  TextStyle get cardHeading => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: white,
        fontSize: 16,
        height: 1.6,
      );

  TextStyle get cardBlurb => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: white,
        fontSize: 13,
        height: 1.6,
      );

  TextStyle get urlBlurb => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF666666),
        fontSize: 13,
      );

  TextStyle get userQuery => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: black,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  TextStyle get videoSeriesTag => const TextStyle(
      fontFamily: 'Roboto-Medium',
      fontWeight: FontWeight.w600,
      color: Color(0x80FFFFFF),
      fontSize: 16);

  TextStyle get videoSeriesTitle =>
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: white);

  TextStyle get videoSeriesBlurb => const TextStyle(fontSize: 16, color: white);

  // Billing History
  TextStyle get receiptHeader => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF888888),
        fontSize: 13,
        height: 1.6,
      );

  TextStyle get receiptRow => receiptHeader.copyWith(
        color: const Color(0xFF333333),
      );

  TextStyle get receiptRowFailed => receiptHeader.copyWith(
        color: const Color(0xFFAAAAAA),
      );

  // Error Page
  TextStyle get errorHeader => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFFF1F1F1), fontSize: 30);

  TextStyle get errorSubHeader => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFFF1F1F1),
      fontSize: 16,
      height: 1.6);

  TextStyle get errorCaption => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF666666),
      fontSize: 16,
      height: 1.6);

  TextStyle get errorAction => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFF333333), fontSize: 16);
}

/// Gradients used in the Rive Theme
/// Define them as getters and keep them const
class Gradients {
  const Gradients();

  LinearGradient get transparentLinear =>
      const LinearGradient(colors: [transparent, transparent]);

  LinearGradient get magenta => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          red,
          purple,
        ],
      );

  LinearGradient get redPurpleBottomCenter => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          red,
          purple,
        ],
      );
}

class TreeStyles {
  const TreeStyles();

  TreeStyle get timeline => const TreeStyle(
        showFirstLine: false,
        hideLines: false,
        padding: EdgeInsets.only(left: 10),
        lineColor: _darkTreeLines,
      );

  TreeStyle get hierarchy => const TreeStyle(
        showFirstLine: true,
        padding: EdgeInsets.only(left: 10, right: 10, top: 5),
        lineColor: _darkTreeLines,
      );
}

/// Not sure about the naming of this one. Basically a set of numerical
/// constants for the theme.
class _Dimensions {
  const _Dimensions();
  double get timelineMarginLeft => 10;
  double get timelineMarginRight => 30;

  double get keySize => 8;
  double get keyLower => (-keySize / 2).floor() + 0.5;
  double get keyUpper => (keySize / 2).floor() + 0.5;

  /// The dimensionsof the click/drag resize edge on panels that support
  /// resizing.
  double get resizeEdgeSize => 10;

  /// Right click popup menu width.
  double get contextMenuWidth => 130;
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
  PlatformSpecific get platform => PlatformSpecific();
  TreeStyles get treeStyles => const TreeStyles();
  _Dimensions get dimensions => const _Dimensions();
}
