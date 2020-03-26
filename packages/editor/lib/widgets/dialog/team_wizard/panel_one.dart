import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_package.dart';
import 'package:rive_editor/widgets/gradient_border.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/utils.dart';

/// The first panel in the teams sign-up wizard
class TeamWizardPanelOne extends StatelessWidget {
  const TeamWizardPanelOne(this.sub, {Key key}) : super(key: key);
  final TeamSubscriptionPackage sub;

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final options = [
      BillingFrequency.yearly,
      BillingFrequency.monthly,
    ];
    return SizedBox(
      width: 452,
      height: 376,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    textAlign: TextAlign.left,
                    textAlignVertical: TextAlignVertical.center,
                    style: textStyles.fileGreyTextLarge,
                    initialValue: sub.name,
                    decoration: InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: colors.inputUnderline, width: 2),
                      ),
                      hintText: 'Team name',
                      errorText: sub.nameValidationError,
                      hintStyle: textStyles.textFieldInputHint,
                      errorStyle: textStyles.textFieldInputValidationError,
                      contentPadding: const EdgeInsets.only(bottom: 3),
                      filled: true,
                      hoverColor: Colors.transparent,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (name) => sub.name = name,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: SizedBox(
                    width: 71,
                    child: ComboBox<BillingFrequency>(
                      popupWidth: 100,
                      sizing: ComboSizing.content,
                      underline: true,
                      underlineColor: colors.inputUnderline,
                      valueColor: textStyles.fileGreyTextLarge.color,
                      options: options,
                      value: sub.billing,
                      toLabel: (option) => describeEnum(option).capsFirst,
                      contentPadding: const EdgeInsets.only(bottom: 3),
                      change: (billing) => sub.billing = billing,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: sub.nameValidationError == null
                  ? const EdgeInsets.only(top: 31, bottom: 31)
                  : const EdgeInsets.only(top: 9, bottom: 31),
              child: Row(
                children: <Widget>[
                  TeamSubscriptionChoiceWidget(
                    label: 'Team',
                    costLabel: '\$14',
                    explanation:
                        'A space where you and your team can share files.',
                    onTap: () => sub.option = TeamsOption.basic,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: TeamSubscriptionChoiceWidget(
                      label: 'Premium Team',
                      costLabel: '\$45',
                      explanation: '1 day support.',
                      onTap: () => sub.option = TeamsOption.premium,
                    ),
                  ),
                ],
              ),
            ),
            RichText(
                text: TextSpan(
              children: [
                const TextSpan(
                    text: 'You\'ll only be billed for users as'
                        ' you add them. Read more about our '),
                TextSpan(
                    text: 'fair billing policy',
                    style: textStyles.tooltipHyperlink,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (await canLaunch(billingPolicyUrl)) {
                          await launch(billingPolicyUrl);
                        }
                      }),
                const TextSpan(text: '.'),
              ],
              style: textStyles.tooltipDisclaimer,
            ))
          ],
        ),
      ),
    );
  }
}

class TeamSubscriptionChoiceWidget extends StatefulWidget {
  final String label;
  final String costLabel;
  final String explanation;
  final VoidCallback onTap;

  const TeamSubscriptionChoiceWidget({
    Key key,
    this.label,
    this.costLabel,
    this.explanation,
    this.onTap,
  }) : super(key: key);

  @override
  _TeamSubscriptionChoiceWidgetState createState() =>
      _TeamSubscriptionChoiceWidgetState();
}

class _TeamSubscriptionChoiceWidgetState
    extends State<TeamSubscriptionChoiceWidget> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final gradient = RiveTheme.of(context).gradients.redPurpleBottomCenter;

    final backgroundColor =
        _hover ? Colors.white : colors.panelBackgroundLightGrey;
    final buttonColor = _hover ? colors.buttonDark : null;
    final buttonTextColor =
        _hover ? Colors.white : colors.commonButtonTextColorDark;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GradientBorder(
          strokeWidth: 3,
          radius: 10,
          shouldPaint: _hover,
          gradient: gradient,
          child: Container(
            height: 193,
            width: 175,
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: backgroundColor,
              boxShadow: _hover
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FlatIconButton(
                        mainAxisAlignment: MainAxisAlignment.center,
                        label: 'Choose',
                        color: buttonColor,
                        textColor: buttonTextColor,
                        elevated: _hover,
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
