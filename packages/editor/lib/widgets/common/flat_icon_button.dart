import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

import 'package:rive_editor/widgets/popup/tip.dart';

class FlatIconButton extends StatefulWidget {
  const FlatIconButton({
    @required this.label,
    Key key,
    this.icon,
    this.color,
    this.textColor,
    this.hoverColor,
    this.hoverTextColor,
    this.onTap,
    this.tip,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.elevated = false,
    this.radius = 15,
    this.height = 30,
  }) : super(key: key);

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final Color color, textColor;
  final Color hoverColor, hoverTextColor;
  final bool elevated;
  final double radius;
  final double height;
  final MainAxisAlignment mainAxisAlignment;

  /// Optional tooltip to show when this button is hovered.
  final Tip tip;

  @override
  _FlatIconState createState() => _FlatIconState();
}

class _FlatIconState extends State<FlatIconButton> {
  bool _isHovered = false;

  Widget _tip(Widget child) => widget.tip == null
      ? child
      : TipRegion(
          tip: widget.tip,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;
    final riveStyles = RiveTheme.of(context).textStyles;
    // Fall back to default color if we don't have a hover specified.
    var hoverColor = widget.hoverColor ?? widget.color; 
    var color = (_isHovered ? hoverColor : widget.color) ??
        riveColors.commonButtonColor;

    // Fall back to default color if we don't have a hover specified.
    var hoverTextColor = widget.hoverTextColor ?? widget.textColor;
    var textColor = _isHovered ? hoverTextColor : widget.textColor;
    var textStyle = (textColor != null)
        ? riveStyles.buttonTextStyle.copyWith(color: textColor)
        : riveStyles.buttonTextStyle;
    return _tip(
      MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: widget.elevated
                  ? [
                      BoxShadow(
                        color: riveColors.commonDarkGrey.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            height: widget.height,
            child: Row(
              mainAxisAlignment: widget.mainAxisAlignment,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  // This correctly aligned the text vertically
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(widget.label, style: textStyle),
                ),
                if (widget.icon != null) widget.icon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
