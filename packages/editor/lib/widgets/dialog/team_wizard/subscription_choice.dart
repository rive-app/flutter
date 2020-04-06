import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/gradient_border.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class TeamSubscriptionChoiceWidget extends StatefulWidget {
  final String label;
  final String costLabel;
  final String explanation;
  final VoidCallback onTap;
  final bool showButton;
  final bool isSelected;

  const TeamSubscriptionChoiceWidget(
      {Key key,
      this.label,
      this.costLabel,
      this.explanation,
      this.onTap,
      this.showButton = true,
      this.isSelected = false})
      : super(key: key);

  @override
  _TeamSubscriptionChoiceWidgetState createState() =>
      _TeamSubscriptionChoiceWidgetState();
}

class _TeamSubscriptionChoiceWidgetState
    extends State<TeamSubscriptionChoiceWidget> {
  var _hover = false;

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
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GradientBorder(
          strokeWidth: 3,
          radius: 10,
          shouldPaint: isHighlighted,
          gradient: gradient,
          child: Container(
            height: 193,
            width: 175,
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
