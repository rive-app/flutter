import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';

import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
// import 'package:url_launcher/url_launcher.dart';

class TeamSubscriptionOption {
  final String name;
  final String value;

  TeamSubscriptionOption(this.name, this.value);
}

Future<T> showTeamWizard<T>({BuildContext context}) {
  return showRiveDialog(
      context: context,
      builder: (context) {
        return WizardPanel();
      });
}

class WizardPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final options = [
      TeamSubscriptionOption('Yearly', 'yearly'),
      TeamSubscriptionOption('Monthly', 'monthly'),
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
                      value: options.first,
                      toLabel: (option) => option.name,
                      contentPadding: const EdgeInsets.only(bottom: 4),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 31, bottom: 31),
              child: Row(
                children: <Widget>[
                  const TeamSubscriptionChoiceWidget(
                    label: 'Team',
                    costLabel: '\$14',
                    explaination:
                        'A space where you and your team can share files.',
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 30),
                    child: TeamSubscriptionChoiceWidget(
                      label: 'Premium Team',
                      costLabel: '\$45',
                      explaination: '1 day support.',
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
                      ..onTap = () {
                        print('Should launch: could use url_launcher'
                            ' for this. its by the flutter team....');
                        // launch('http://bitly.com/98K8eH');
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

class TeamSubscriptionChoiceWidget extends StatelessWidget {
  final String label;
  final String costLabel;
  final String explaination;

  const TeamSubscriptionChoiceWidget(
      {Key key, this.label, this.costLabel, this.explaination})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    return Container(
      height: 199,
      width: 181,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: colors.panelBackgroundLightGrey),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  child: Text(
                label,
                style: textStyles.fileGreyTextLarge,
              )),
              RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(children: [
                    TextSpan(
                      text: costLabel,
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
                      style: textStyles.fileLightGreyText.copyWith(height: 1.6),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      explaination,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      style: textStyles.fileLightGreyText.copyWith(height: 1.6),
                    ),
                  )
                ],
              ),
            ),
          ),
          Row(
            children: <Widget>[
              const Expanded(
                child: FlatIconButton(
                  mainAxisAlignment: MainAxisAlignment.center,
                  label: 'Choose',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
