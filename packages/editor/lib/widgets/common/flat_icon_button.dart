import 'package:flutter/material.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/tip.dart';

class FlatIconButton extends StatelessWidget {
  const FlatIconButton({
    @required this.label,
    Key key,
    this.icon,
    this.color,
    this.textColor,
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
  final bool elevated;
  final double radius;
  final double height;
  final MainAxisAlignment mainAxisAlignment;

  /// Optional tooltip to show when this button is hovered.
  final Tip tip;

  Widget _tip(Widget child) => tip == null
      ? child
      : TipRegion(
          tip: tip,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    return _tip(
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: color ?? RiveTheme.of(context).colors.commonButtonColor,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: RiveTheme.of(context)
                          .colors
                          .commonDarkGrey
                          .withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          height: height,
          child: Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                // This correctly aligned the text vertically
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor ??
                        RiveTheme.of(context).colors.commonButtonTextColor,
                    fontSize: 13,
                  ),
                ),
              ),
              if (icon != null) ...[icon],
            ],
          ),
        ),
      ),
    );
  }
}
