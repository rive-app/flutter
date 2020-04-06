import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
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
    PlanSubscriptionPackage.fetchData(widget.api, widget.team.ownerId)
        .then((value) => setState(() {
              _sub = value;
            }));

    super.initState();
  }

  @override
  void dispose() {
    _sub.dispose();
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
          SettingsPanelSection(label: 'Bill', contents: (ctx) => Row()),
        ]);
  }
}
