import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
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

  /// Optional tooltip to show when this button is hovered.
  final Tip tip;

  /// Called when the hover state changes.
  final ValueChanged<bool> onHover;

  const TintedIconButton({
    @required this.icon,
    this.onPress,
    this.background,
    this.color,
    this.backgroundHover,
    this.iconHover,
    this.padding,
    this.tip,
    this.onHover,
    Key key,
  }) : super(key: key);
  @override
  _TintedIconButtonState createState() => _TintedIconButtonState();
}

class _TintedIconButtonState extends State<TintedIconButton> {
  bool _isHovered = false;

  Widget _tip(Widget child) {
    if (widget.tip == null) {
      return child;
    }
    return TipRegion(
      tip: widget.tip,
      child: child,
    );
  }

  Widget _gesture(Widget child) {
    if (widget.onPress == null) {
      return child;
    }
    return GestureDetector(
      onTapDown: (_) => widget.onPress(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = RiveTheme.of(context).colors;

    final backgroundHover = _isHovered
        ? widget.backgroundHover ?? themeColors.toolbarButtonBackGroundHover
        : Colors.transparent;

    final iconHover = _isHovered
        ? widget.iconHover ?? themeColors.toolbarButtonHover
        : themeColors.toolbarButton;
    return _tip(
      _gesture(
        MouseRegion(
          onEnter: (_) {
            // If there's a drag operation active, don't show the hover.
            if (RiveContext.find(context).isDragging) {
              return;
            }
            setState(() {
              _isHovered = true;
              widget.onHover?.call(true);
            });
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
              widget.onHover?.call(false);
            });
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
      ),
    );
  }
}
