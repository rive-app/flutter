import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/rive_radio.dart';
import 'package:rive_editor/widgets/gradient_border.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class TeamSubscriptionChoiceWidget extends StatefulWidget {
  final String label;
  final String costLabel;
  final String explanation;
  final VoidCallback onTap;
  final bool showButton;
  final bool isSelected;
  final double borderThickness;

  const TeamSubscriptionChoiceWidget(
      {Key key,
      this.label,
      this.costLabel,
      this.explanation,
      this.onTap,
      this.borderThickness = 3,
      this.showButton = true,
      this.isSelected = false})
      : super(key: key);

  @override
  _TeamSubscriptionChoiceWidgetState createState() =>
      _TeamSubscriptionChoiceWidgetState();
}

class _TeamSubscriptionChoiceWidgetState
    extends State<TeamSubscriptionChoiceWidget> {
  bool _hover = false;
  void setHover(bool hover) => setState(() => _hover = hover);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    final gradient = theme.gradients.redPurpleBottomCenter;

    final isHighlighted = _hover || widget.isSelected;

    final backgroundColor =
        isHighlighted ? Colors.white : colors.panelBackgroundLightGrey;
    final buttonColor = isHighlighted ? colors.buttonDark : null;
    final buttonTextColor =
        isHighlighted ? Colors.white : colors.commonButtonTextColorDark;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setHover(true),
        onExit: (_) => setHover(false),
        child: GradientBorder(
          strokeWidth: widget.borderThickness,
          radius: 10,
          shouldPaint: isHighlighted,
          gradient: gradient,
          child: Container(
            height: 193,
            width: 181,
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: backgroundColor,
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: colors.commonButtonColor,
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      )
                    ]
                  : null,
            ),
            child: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                        child: Text(
                      widget.label,
                      style: textStyles.fileGreyTextLarge,
                    )),
                    RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(children: [
                          TextSpan(
                            text: widget.costLabel,
                            style: textStyles.fileGreyTextLarge,
                          ),
                          TextSpan(
                            text: '/mo\n per user',
                            style: textStyles.fileGreyTextSmall,
                          )
                        ])),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 9),
                          child: Text(
                            '+',
                            style: textStyles.fileLightGreyText
                                .copyWith(height: 1.6),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.explanation,
                            overflow: TextOverflow.visible,
                            softWrap: true,
                            style: textStyles.fileLightGreyText
                                .copyWith(height: 1.6),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                if (widget.showButton)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FlatIconButton(
                          mainAxisAlignment: MainAxisAlignment.center,
                          label: 'Choose',
                          color: buttonColor,
                          textColor: buttonTextColor,
                          elevated: isHighlighted,
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionChoiceRadio extends StatefulWidget {
  final String label;
  final String costLabel;
  final String description;
  final VoidCallback onTap;
  final ValueChanged<bool> onHoverChange;
  // Whether this subscription option has been selected.
  final bool isSelected;
  // Interpolation value for the highlight of this widget.
  final double highlight;

  const SubscriptionChoiceRadio({
    this.label,
    this.costLabel,
    this.description,
    this.onTap,
    this.onHoverChange,
    this.isSelected = false,
    this.highlight = 0,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubscriptionChoiceState();
}

class _SubscriptionChoiceState extends State<SubscriptionChoiceRadio>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  void setHover(bool hover) => setState(() {
        _hover = hover;
        widget.onHoverChange?.call(_hover);
      });

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    final gradients = theme.gradients;
    final animationValue = widget.highlight;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setHover(true),
        onExit: (_) => setHover(false),
        child: Padding(
          padding: EdgeInsets.only(
            top: lerpDouble(2, 0, animationValue),
            bottom: lerpDouble(0, 2, animationValue),
          ),
          child: GradientBorder(
            strokeWidth: 3,
            radius: 10,
            shouldPaint: true,
            // gradient: gradient,
            gradient: LinearGradient.lerp(gradients.transparentLinear,
                gradients.redPurpleBottomCenter, animationValue),
            child: Container(
              height: 187,
              width: 181,
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color.lerp(colors.panelBackgroundLightGrey,
                      Colors.white, animationValue),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(Colors.transparent,
                          colors.commonButtonColor, animationValue),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: [
                    RiveRadio<bool>(
                        groupValue: true,
                        value: widget.isSelected,
                        onChanged: (_) => widget.onTap,
                        backgroundColor: Color.lerp(colors.buttonLight,
                            colors.toggleInactiveBackground, animationValue)),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: textStyles.fileGreyTextLarge,
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(widget.description,
                              overflow: TextOverflow.visible,
                              softWrap: true,
                              style: textStyles.fileLightGreyText.copyWith(
                                  height: 1.6,
                                  color: Color.lerp(
                                      colors.commonButtonTextColorDark,
                                      colors.commonLightGrey,
                                      animationValue))
                              // isHighlighted
                              //     ? colors.commonLightGrey
                              //     : colors.commonButtonTextColorDark),
                              ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  RichText(
                      text: TextSpan(children: [
                    TextSpan(
                      text: '\$' + widget.costLabel,
                      style: textStyles.fileGreyTextLarge,
                    ),
                    TextSpan(
                      text: '/mo per user',
                      style: textStyles.fileGreyTextSmall,
                    )
                  ])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
