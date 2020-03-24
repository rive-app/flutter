import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';

import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/gradient_border.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

const billingPolicyUrl = 'http://bitly.com/98K8eH';

Future<T> showTeamWizard<T>({BuildContext context}) {
  return showRiveDialog(
      context: context,
      builder: (context) {
        return WizardPanel();
      });
}

/// The subscription frequency options
enum TeamSubscriptionOption { yearly, monthly }

/// Data class for tracking data in the team subscription widget
class TeamSubscriptionPackage {
  /// The team name
  String name;

  /// The team subscription option
  TeamSubscriptionOption option = TeamSubscriptionOption.yearly;
}

/// The main panel for holding the team wizard views
class WizardPanel extends StatefulWidget {
  @override
  _WizardPanelState createState() => _WizardPanelState();
}

class _WizardPanelState extends State<WizardPanel> {
  final _sub = TeamSubscriptionPackage();

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final options = [
      TeamSubscriptionOption.yearly,
      TeamSubscriptionOption.monthly,
    ];

    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.left,
                    textAlignVertical: TextAlignVertical.center,
                    style: textStyles.fileGreyTextLarge,
                    decoration: InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: colors.inputUnderline, width: 2)),
                      hintText: 'Team name',
                      hintStyle: textStyles.textFieldInputHint,
                      contentPadding: const EdgeInsets.only(bottom: 3),
                      filled: true,
                      hoverColor: Colors.transparent,
                      fillColor: Colors.transparent,
                    ),
                    // TODO: validate name
                    onChanged: (name) => _sub.name = name,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: SizedBox(
                    width: 71,
                    child: ComboBox<TeamSubscriptionOption>(
                      popupWidth: 100,
                      sizing: ComboSizing.content,
                      underline: true,
                      underlineColor: colors.inputUnderline,
                      valueColor: textStyles.fileGreyTextLarge.color,
                      options: options,
                      value: _sub.option,
                      toLabel: describeEnum,
                      contentPadding: const EdgeInsets.only(bottom: 4),
                      change: (option) => setState(() => _sub.option = option),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 31, bottom: 31),
              child: Row(
                children: const <Widget>[
                  TeamSubscriptionChoiceWidget(
                    label: 'Team',
                    costLabel: '\$14',
                    explanation:
                        'A space where you and your team can share files.',
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 30),
                    child: TeamSubscriptionChoiceWidget(
                      label: 'Premium Team',
                      costLabel: '\$45',
                      explanation: '1 day support.',
                    ),
                  ),
                ],
              ),
            ),
            RichText(
                text: TextSpan(
              children: [
                const TextSpan(
                    text: "You'll only be billed for useres as"
                        " you add them. Read more about our "),
                TextSpan(
                    text: "fair billing policy",
                    style: textStyles.tooltipHyperlink,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        print('Should launch: could use url_launcher'
                            ' for this. its by the flutter team....');
                        //WindowUtils.openWebView(
                        //    'billing_policy', 'https://rive.app');
                        if (await canLaunch(billingPolicyUrl)) {
                          await launch(billingPolicyUrl);
                        }
                      }),
                const TextSpan(text: "."),
              ],
              style: textStyles.tooltipDisclaimer,
            ))
          ],
        ),
      ),
      width: 452,
      height: 376,
    );
  }
}

class TeamSubscriptionChoiceWidget extends StatefulWidget {
  final String label;
  final String costLabel;
  final String explanation;

  const TeamSubscriptionChoiceWidget(
      {Key key, this.label, this.costLabel, this.explanation})
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
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final gradient = RiveTheme.of(context).gradients.redPurpleBottomCenter;

    final backgroundColor =
        _hover ? Colors.white : colors.panelBackgroundLightGrey;
    final buttonColor = _hover ? colors.buttonDark : null;
    final buttonTextColor =
        _hover ? Colors.white : colors.commonButtonTextColorDark;

    return MouseRegion(
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
    );
  }
}
