import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/team_settings/panel_section.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_choice.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_package.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class PlanSettings extends StatefulWidget {
  final RiveTeam team;
  final RiveApi api;
  const PlanSettings(this.team, this.api);

  @override
  State<StatefulWidget> createState() => _PlanState();
}

class _PlanState extends State<PlanSettings> {
  PlanSubscriptionPackage _sub;
  @override
  void initState() {
    // Fetch current team billing data from the backend.
    PlanSubscriptionPackage.fetchData(widget.api, widget.team)
        .then((value) => setState(() {
              _sub = value;
              _sub.addListener(_onSubChange);
            }));
    super.initState();
  }

  void _onSubChange() => setState(() {});

  void _onBillChanged() {
    // TODO: update backend?
    print("Current plan is: ${_sub.billing.name}, ${_sub.option.name}");
  }

  @override
  void dispose() {
    _sub.dispose(); // Cleans up listeners.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;

    return ListView(
        padding: const EdgeInsets.all(30),
        physics: const ClampingScrollPhysics(),
        children: [
          SettingsPanelSection(
              label: 'Account',
              contents: (panelCtx) {
                return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: <Widget>[
                          ComboBox<BillingFrequency>(
                            popupWidth: 100,
                            sizing: ComboSizing.content,
                            underline: true,
                            underlineColor: colors.inputUnderline,
                            valueColor: textStyles.fileGreyTextLarge.color,
                            options: BillingFrequency.values,
                            value: _sub?.billing ?? BillingFrequency.monthly,
                            toLabel: (option) => describeEnum(option).capsFirst,
                            contentPadding: const EdgeInsets.only(bottom: 3),
                            change: (billing) => _sub.billing = billing,
                          ),
                          const Spacer(),
                          GestureDetector(
                              onTap: () {}, child: const Text('Cancel Plan')),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: <Widget>[
                          TeamSubscriptionChoiceWidget(
                            label: 'Team',
                            costLabel: '\$$basicMonthlyCost',
                            explanation:
                                'A space where you and your team can share files.',
                            onTap: () => _sub.option = TeamsOption.basic,
                            showButton: false,
                            isSelected: _sub?.option == TeamsOption.basic,
                          ),
                          const SizedBox(width: 30),
                          TeamSubscriptionChoiceWidget(
                            label: 'Premium Team',
                            costLabel: '\$$premiumMonthlyCost',
                            explanation: '1 day support.',
                            onTap: () => _sub.option = TeamsOption.premium,
                            showButton: false,
                            isSelected: _sub?.option == TeamsOption.premium,
                          ),
                        ],
                      ),
                    ]);
              }),
          // Vertical padding.
          const SizedBox(height: 30),
          Separator(color: colors.fileLineGrey),
          // Vertical padding.
          const SizedBox(height: 30),
          SettingsPanelSection(label: 'Payment', contents: (ctx) => Row()),
          // Vertical padding.
          const SizedBox(height: 30),
          Separator(color: colors.fileLineGrey),
          // Vertical padding.
          const SizedBox(height: 30),
          BillCalculator(
            subscription: _sub,
            onBillChanged: _onBillChanged
          ),
        ]);
  }
}

class BillCalculator extends StatelessWidget {
  final VoidCallback onBillChanged;
  final PlanSubscriptionPackage subscription;

  const BillCalculator({this.subscription, this.onBillChanged, Key key})
      : super(key: key);

  BillingFrequency get plan => subscription.billing;
  int get costDifference =>
      subscription.calculatedCost - subscription.currentCost;

  Widget _nextCharge(TextStyle light, TextStyle dark) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: 'Starting ', style: light),
        // TODO: get the date from subscription.
        TextSpan(
            text: 'Jan 20, 2021',
            style: dark.copyWith(fontFamily: 'Roboto-Regular')),
        TextSpan(text: ' your will be billed monthly', style: light)
      ]),
    );
  }

  List<Widget> _credit(TextStyle light, TextStyle dark, Color buttonColor) {
    return [
      _nextCharge(light, dark),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('New ${plan.name} bill', style: light),
                const SizedBox(height: 10),
                Text('Pay now', style: light)
              ]),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${subscription.calculatedCost}',
                style: dark.copyWith(fontFamily: 'Roboto-Regular')),
            const SizedBox(height: 10),
            Text('\$0', style: dark.copyWith(fontWeight: FontWeight.bold))
          ]),
        ],
      ),
      const SizedBox(height: 25),
      FlatIconButton(
          label: 'Confirm',
          color: buttonColor,
          textColor: Colors.white,
          onTap: onBillChanged),
    ];
  }

  List<Widget> _debit(TextStyle light, TextStyle dark, Color buttonColor) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('New ${plan.name} bill', style: light),
                const SizedBox(height: 10),
                Text('Pay now (prorated)', style: light)
              ]),
          const SizedBox(width: 10),
          Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text('\$${subscription.calculatedCost}',
                    style: dark.copyWith(fontFamily: 'Roboto-Regular')),
                const SizedBox(height: 10),
                Text('\$$costDifference', style: dark)
              ]),
        ],
      ),
      const SizedBox(height: 25),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FlatIconButton(
              label: 'Confirm & Pay',
              color: buttonColor,
              textColor: Colors.white,
              onTap: onBillChanged),
        ],
      ),
    ];
  }

  Widget _yearlyBill(TextStyle light, TextStyle dark) {
    final plan = subscription.billing;
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: '${plan.name.capsFirst} bill\t',
          style: light,
        ),
        TextSpan(
          text: '\$${subscription?.currentCost ?? '-'}',
          style: dark,
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: use FutureBuilder?
    if (subscription?.currentCost == null) {
      return const SizedBox();
    }
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;

    final lightGreyText =
        textStyles.hierarchyTabHovered.copyWith(fontSize: 13, height: 1.6);
    final darkGreyText = textStyles.notificationTitle.copyWith(
        fontFamily: 'Roboto-Medium', fontWeight: FontWeight.w700, height: 1.6);
    final buttonColor = colors.commonDarkGrey;
    final diff = costDifference;

    return SettingsPanelSection(
        label: 'Bill',
        contents: (ctx) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (diff == 0) _yearlyBill(lightGreyText, darkGreyText),
                if (diff > 0)
                  ..._debit(lightGreyText, darkGreyText, buttonColor),
                if (diff < 0)
                  ..._credit(lightGreyText, darkGreyText, buttonColor),
              ],
            ));
  }
}
