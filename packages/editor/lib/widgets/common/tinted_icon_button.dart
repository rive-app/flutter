import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// A tinted icon button following Rive design guidelines with background
/// highlight on hover.
class TintedIconButton extends StatefulWidget {
  /// Callback for when the button is pressed.
  final VoidCallback onPress;

  /// Override background color of icon, defaults to Rive theme values.
  final Color background;

  /// Override foreground color of icon, defaults to Rive theme values.
  final Color color;

  /// Override default background hover color, defaults to Rive theme values.
  final Color backgroundHover;

  // Override default icon hover color. Defaults to Rive theme values.
  final Color iconHover;

  // Override default padding values for the icon. Defaults [EdgeInsets.all(5)].
  final EdgeInsets padding;

  /// The icon's name which resolves to an image in the icon assets folder.
  final String icon;

  const TintedIconButton({
    @required this.onPress,
    @required this.icon,
    this.background,
    this.color,
    this.backgroundHover,
    this.iconHover,
    this.padding,
    Key key,
  }) : super(key: key);
  @override
  _TintedIconButtonState createState() => _TintedIconButtonState();
}

class _TintedIconButtonState extends State<TintedIconButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final themeColors = RiveTheme.of(context).colors;

    final backgroundHover = _isHovered
        ? widget.backgroundHover ?? themeColors.toolbarButtonBackGroundHover
        : Colors.transparent;

    final iconHover = _isHovered
        ? widget.iconHover ?? themeColors.toolbarButtonHover
        : themeColors.toolbarButton;
    return GestureDetector(
      onTapDown: (_) => widget.onPress(),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
        },
        onExit: (_) {
          setState(() => _isHovered = false);
        },
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: widget.background ?? backgroundHover,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: TintedIcon(
              color: widget.color ?? iconHover,
              icon: widget.icon,
            ),
          ),
        ),
      ),
    );
  }
}
