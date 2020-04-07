import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/team_settings/panel_section.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/panel_two.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_choice.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_package.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

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
    // TODO: track response?
    _sub.updatePlan(widget.api, widget.team.ownerId);
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            // Align text baseline with label & button.
                            padding: const EdgeInsets.only(top: 3),
                            child: ComboBox<BillingFrequency>(
                              popupWidth: 100,
                              sizing: ComboSizing.content,
                              underline: true,
                              underlineColor: colors.inputUnderline,
                              valueColor: textStyles.fileGreyTextLarge.color,
                              options: BillingFrequency.values,
                              value: _sub?.billing ?? BillingFrequency.monthly,
                              toLabel: (option) =>
                                  describeEnum(option).capsFirst,
                              change: (billing) => _sub.billing = billing,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                              onTap: () {/** TODO: cancel plan */},
                              child: Text('Cancel Plan',
                                  style: textStyles.fileGreyTextLarge.copyWith(
                                    fontSize: 12,
                                    height: 1.6,
                                    decoration: TextDecoration.underline,
                                  ))),
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
          PaymentMethod(_sub),
          // Vertical padding.
          const SizedBox(height: 30),
          Separator(color: colors.fileLineGrey),
          // Vertical padding.
          const SizedBox(height: 30),
          BillCalculator(subscription: _sub, onBillChanged: _onBillChanged),
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
                Text('Pay now', style: light),
              ]),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${subscription.calculatedCost}',
                style: dark.copyWith(fontFamily: 'Roboto-Regular')),
            const SizedBox(height: 10),
            Padding(
                padding: const EdgeInsets.only(bottom: 2.0), // Align amount.
                child: Text('\$0',
                    style: dark.copyWith(fontWeight: FontWeight.bold)))
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
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('New ${plan.name} bill', style: light),
            const SizedBox(height: 10),
            Text('Pay now (prorated)', style: light)
          ]),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${subscription.calculatedCost}',
                style: dark.copyWith(fontFamily: 'Roboto-Regular')),
            const SizedBox(height: 10),
            Padding(
                padding: const EdgeInsets.only(bottom: 2.0), // Align amount.
                child: Text('\$$costDifference', style: dark))
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
        textStyles.hierarchyTabHovered.copyWith(fontSize: 13, height: 1.4);
    final darkGreyText = textStyles.notificationTitle.copyWith(
        fontFamily: 'Roboto-Medium', fontWeight: FontWeight.w700, height: 1.4);
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

class PaymentMethod extends StatefulWidget {
  final PlanSubscriptionPackage sub;

  const PaymentMethod(this.sub, {Key key}) : super(key: key);

  @override
  _MethodState createState() => _MethodState();
}

class _MethodState extends State<PaymentMethod> {
  bool _useSaved = true;

  void _changeView(bool useSaved) {
    setState(() {
      _useSaved = useSaved;
    });
  }

  Widget _nextPayment(Color iconColor, TextStyles styles) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TintedIcon(icon: 'date', color: iconColor),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(children: [
            TextSpan(
                text: 'Next payment due: ',
                style: styles.hierarchyTabHovered
                    .copyWith(fontSize: 13, height: 1.4)),
            TextSpan(
                // TODO: get date from subscription.
                text: 'Jan 20, 2021',
                style: styles.fileGreyTextLarge.copyWith(
                  fontSize: 13,
                  height: 1.15,
                )),
          ]),
        )
      ],
    );
  }

  Widget _underlineButton(String label, TextStyles styles, bool toSaved) {
    return GestureDetector(
      onTap: () => _changeView(toSaved),
      child: Text(label,
          style: styles.fileGreyTextLarge.copyWith(
            fontSize: 12,
            decoration: TextDecoration.underline,
          )),
    );
  }

  Widget _savedInfo(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    final colors = theme.colors;

    return Column(
      children: <Widget>[
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          TintedIcon(icon: 'card', color: colors.commonButtonTextColor),
          const SizedBox(width: 10),
          Text('American Express 1007. Expires 10/2022',
              style:
                  styles.fileGreyTextLarge.copyWith(fontSize: 13, height: 1.4)),
          const Spacer(),
          _underlineButton('Change', styles, false),
        ]),
        const SizedBox(height: 15),
        _nextPayment(colors.commonButtonTextColor, styles)
      ],
    );
  }

  Widget _cardInput(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    final colors = theme.colors;
    return Column(
      children: [
        CreditCardForm(
            sub: widget.sub,
            trailingButtonBuilder: (_) =>
                _underlineButton('Use saved card instead', styles, true)),
        const SizedBox(height: 30),
        _nextPayment(colors.commonButtonTextColor, styles)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPanelSection(
      label: 'Payment',
      contents: (ctx) => _useSaved ? _savedInfo(ctx) : _cardInput(ctx),
    );
  }
}

class CreditCardForm extends StatelessWidget {
  final SubscriptionPackage sub;
  final WidgetBuilder trailingButtonBuilder;

  const CreditCardForm({this.sub, this.trailingButtonBuilder, Key key})
      : super(key: key);

  Widget _creditCardNumber(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    final colors = theme.colors;
    return Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'Card Number',
            style: styles.inspectorPropertyLabel.copyWith(height: 1.4),
          ),
          const Spacer(),
          if (trailingButtonBuilder != null) trailingButtonBuilder(context)
        ],
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: sub.cardNumber,
        cursorColor: colors.commonDarkGrey,
        textAlign: TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        style: styles.fileGreyTextLarge.copyWith(fontSize: 13),
        inputFormatters: <TextInputFormatter>[
          WhitelistingTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
          CardNumberFormatter()
        ],
        decoration: InputDecoration(
          isDense: true,
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.inputUnderline, width: 2)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.commonDarkGrey, width: 2)),
          hintText: '0000 0000 0000 0000',
          hintStyle: styles.textFieldInputHint.copyWith(fontSize: 13),
          errorStyle: styles.textFieldInputValidationError,
          contentPadding: const EdgeInsets.only(bottom: 3),
        ),
        onChanged: (cardNumber) => sub.cardNumber = cardNumber,
      )
    ]);
  }

  Widget _creditCardDetails(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    final colors = theme.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // CVV
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CVC/CVV',
                style: styles.inspectorPropertyLabel,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: sub.ccv,
                cursorColor: colors.commonDarkGrey,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: styles.fileGreyTextLarge.copyWith(fontSize: 13),
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colors.inputUnderline, width: 2)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colors.commonDarkGrey, width: 2)),
                  hintText: '3-4 digits',
                  hintStyle: styles.textFieldInputHint.copyWith(fontSize: 13),
                  errorStyle: styles.textFieldInputValidationError,
                  contentPadding: const EdgeInsets.only(bottom: 3),
                ),
                onChanged: (ccv) => sub.ccv = ccv,
              ),
            ],
          ),
        ),
        const SizedBox(width: 30),
        // Expiration
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expiration',
                style: styles.inspectorPropertyLabel,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: sub.expiration,
                cursorColor: colors.commonDarkGrey,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: styles.fileGreyTextLarge.copyWith(fontSize: 13),
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  DateTextInputFormatter(),
                  DateTextRegexCheck()
                ],
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colors.inputUnderline, width: 2)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colors.commonDarkGrey, width: 2)),
                  hintText: 'MM/YY',
                  hintStyle: styles.textFieldInputHint.copyWith(fontSize: 13),
                  errorStyle: styles.textFieldInputValidationError,
                  contentPadding: const EdgeInsets.only(bottom: 3),
                ),
                onChanged: (expiration) => sub.expiration = expiration,
              ),
            ],
          ),
        ),
        const SizedBox(width: 30),
        // Zip
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zip',
                style: styles.inspectorPropertyLabel,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: sub.zip,
                cursorColor: colors.commonDarkGrey,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: styles.fileGreyTextLarge.copyWith(fontSize: 13),
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colors.inputUnderline, width: 2)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colors.commonDarkGrey, width: 2)),
                  hintText: '90210',
                  hintStyle: styles.textFieldInputHint.copyWith(fontSize: 13),
                  errorStyle: styles.textFieldInputValidationError,
                  contentPadding: const EdgeInsets.only(bottom: 3),
                ),
                onChanged: (zip) => sub.zip = zip,
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: use FutureBuilder?
    if (sub == null) {
      return const SizedBox();
    }
    return Column(
      children: [
        _creditCardNumber(context),
        const SizedBox(height: 30),
        _creditCardDetails(context),
      ],
    );
  }
}
