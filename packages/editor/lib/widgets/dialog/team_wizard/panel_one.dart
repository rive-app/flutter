import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/rive_text_field.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_choice.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_package.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// The first panel in the teams sign-up wizard
class TeamWizardPanelOne extends StatefulWidget {
  const TeamWizardPanelOne(this.sub, {Key key}) : super(key: key);
  final TeamSubscriptionPackage sub;

  @override
  State<StatefulWidget> createState() => _ChoicePanelState();
}

class _ChoicePanelState extends State<TeamWizardPanelOne>
    with TickerProviderStateMixin {
  AnimationController _basicController, _premiumController;

  @override
  void initState() {
    _basicController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _premiumController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    super.initState();
  }

  @override
  void dispose() {
    _basicController.dispose();
    _premiumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double targetPadding = 30;
    const double subscriptionBorderThickness = 3;
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    final sub = widget.sub;

    return SizedBox(
      width: 452,
      height: 399,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: targetPadding - subscriptionBorderThickness,
            vertical: targetPadding),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: subscriptionBorderThickness),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: RiveTextField(
                      onChanged: (name) => sub.name = name,
                      enabled: !sub.processing,
                      initialValue: sub.name,
                      fontSize: 16,
                      hintText: 'Team name',
                      errorText: sub.nameValidationError,
                      errorAlignment: MainAxisAlignment.start,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: SizedBox(
                      width: 71,
                      child: ComboBox<BillingFrequency>(
                        popupWidth: 100,
                        sizing: ComboSizing.sized,
                        underline: true,
                        underlineColor: colors.inputUnderline,
                        valueColor: textStyles.fileGreyTextLarge.color,
                        options: BillingFrequency.values,
                        value: sub.billing,
                        toLabel: (option) => describeEnum(option).capsFirst,
                        contentPadding: const EdgeInsets.only(bottom: 3),
                        change: (billing) => sub.billing = billing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: sub.nameValidationError == null
                  ? const EdgeInsets.only(top: 25, bottom: 23)
                  : const EdgeInsets.only(top: 5, bottom: 23),
              child: Row(
                children: [
                  MouseRegion(
                    onEnter: (_) => _basicController.forward(),
                    onExit: (_) => _basicController.reverse(),
                    child: AnimatedBuilder(
                      animation: _basicController,
                      builder: (_, __) {
                        final t = _basicController.value;
                        final animationValue = t * t;
                        final labelLookup = costLookup[sub?.billing];
                        return SubscriptionChoice(
                          label: 'Team',
                          costLabel: sub == null
                              ? ''
                              : '${labelLookup[TeamsOption.basic]}',
                          description: 'A space where you and your team'
                              ' can share files.',
                          onTap: () => sub.option = TeamsOption.basic,
                          showRadio: false,
                          highlight: animationValue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  MouseRegion(
                    // onEnter: (_) => _premiumController.forward(),
                    // onExit: (_) => _premiumController.reverse(),
                    child: AnimatedBuilder(
                      animation: _premiumController,
                      builder: (_, __) {
                        final t = _premiumController.value;
                        final animationValue = t * t;
                        final labelLookup = costLookup[sub?.billing];
                        return SubscriptionChoice(
                          label: 'Org',
                          disabled: true,
                          costLabel: sub == null
                              ? ''
                              : '${labelLookup[TeamsOption.premium]}',
                          description: 'Create projects that only some of '
                              'your team has access to.',
                          onTap: () => sub.option = TeamsOption.premium,
                          showRadio: false,
                          highlight: animationValue,
                        );
                      },
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
              style: textStyles.tooltipDisclaimer.copyWith(
                // want line height to be 21px
                height: 21 / textStyles.tooltipDisclaimer.fontSize,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
