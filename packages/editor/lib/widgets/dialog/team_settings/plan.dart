import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/rive_text_field.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/underline_text_button.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/team_settings/panel_section.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/panel_two.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_choice.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_package.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

typedef void BoolCallback(bool flag);

class PlanSettings extends StatefulWidget {
  final Team team;
  final RiveApi api;
  const PlanSettings(this.team, this.api);

  @override
  State<StatefulWidget> createState() => _PlanState();
}

class _PlanState extends State<PlanSettings>
    with SingleTickerProviderStateMixin {
  PlanSubscriptionPackage _sub;
  AnimationController _controller;
  bool _usingSavedCC = true;

  bool get isBasic => _sub?.option == TeamsOption.basic;
  bool get isPremium => _sub?.option == TeamsOption.premium;

  @override
  void initState() {
    // Fetch current team billing data from the backend.
    PlanSubscriptionPackage.fetchData(widget.api, widget.team).then(
      (value) => setState(
        () {
          _sub = value;
          _controller.value = _sub.option == TeamsOption.basic ? 1 : 0;

          // // Toggle upon receiving the new value.
          // _toggleController();

          // Listen for upcoming changes.
          _sub.addListener(_onSubChange);
        },
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    TeamManager().getCustomerInfo(widget.team);

    super.initState();
  }

  void _onSubChange() => setState(_toggleController);

  Future<void> _onBillChanged() async {
    if (!_usingSavedCC) {
      if (await _sub.updateCard(widget.team)) {
        setState(() {
          // Check the new CC info.
          print("Success!");
        });
      }
    }
    return;
    // TODO: process payment after updating the card.
    _sub.updatePlan(widget.api, widget.team.ownerId);
  }

  void _toggleController() {
    if (isBasic) {
      _controller.forward();
    } else if (isPremium) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _sub.dispose(); // Cleans up listeners.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sub == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    final labelLookup = costLookup[_sub?.billing];
    return ListView(
      padding: const EdgeInsets.all(30),
      physics: const ClampingScrollPhysics(),
      children: [
        SettingsPanelSection(
          label: 'Plan',
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
                        toLabel: (option) => describeEnum(option).capsFirst,
                        change: (billing) => _sub.billing = billing,
                      ),
                    ),
                    const Spacer(),
                    UnderlineTextButton(
                      text: 'Cancel Plan',
                      onPressed: () {/** TODO: cancel plan */},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final t = _controller.value;
                    // Simple quadratic.
                    final animationValue = t * t;
                    return SizedBox(
                      height: 179,
                      child: Row(
                        children: [
                          SubscriptionChoice(
                            label: 'Team',
                            costLabel: '${labelLookup[TeamsOption.basic]}',
                            description: 'Create a space where you and '
                                'your team can share files.',
                            onTap: () => _sub.option = TeamsOption.basic,
                            isSelected: isBasic,
                            highlight: animationValue,
                            showRadio: true,
                          ),
                          const SizedBox(width: 30),
                          SubscriptionChoice(
                            label: 'Org',
                            // disabled: true,
                            costLabel: '${labelLookup[TeamsOption.premium]}',
                            description: ''
                                'Create sub-teams with centralized '
                                'billing',
                            onTap: () => _sub.option = TeamsOption.premium,
                            isSelected: isPremium,
                            highlight: 1 - animationValue,
                            showRadio: true,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        // Vertical padding.
        const SizedBox(height: 30),
        Separator(color: colors.fileLineGrey),
        // Vertical padding.
        const SizedBox(height: 30),
        PaymentMethod(
          _sub,
          onUseSaved: (isUsingSaved) {
            setState(() {
              _usingSavedCC = isUsingSaved;
            });
          },
        ),
        // Vertical padding.
        const SizedBox(height: 30),
        Separator(color: colors.fileLineGrey),
        // Vertical padding.
        const SizedBox(height: 30),
        BillCalculator(
          subscription: _sub,
          onBillChanged: _onBillChanged,
          updatingCC: !_usingSavedCC,
        ),
      ],
    );
  }
}

class BillCalculator extends StatelessWidget {
  final VoidCallback onBillChanged;
  final PlanSubscriptionPackage subscription;
  final bool updatingCC;

  const BillCalculator({
    this.subscription,
    this.onBillChanged,
    this.updatingCC,
    Key key,
  }) : super(key: key);

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
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${subscription.calculatedCost}',
                  style: dark.copyWith(fontFamily: 'Roboto-Regular')),
              const SizedBox(height: 10),
              Padding(
                  padding: const EdgeInsets.only(bottom: 2.0), // Align amount.
                  child: Text('\$0',
                      style: dark.copyWith(fontWeight: FontWeight.bold)))
            ],
          ),
        ],
      ),
      const SizedBox(height: 25),
      FlatIconButton(
        label: 'Confirm',
        color: buttonColor,
        textColor: Colors.white,
        onTap: onBillChanged,
        elevation: 8,
      ),
    ];
  }

  List<Widget> _debit(TextStyle light, TextStyle dark, Color buttonColor) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('New ${plan.name} bill', style: light),
              const SizedBox(height: 10),
              Text('Pay now (prorated)', style: light)
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${subscription.calculatedCost}',
                  style: dark.copyWith(fontFamily: 'Roboto-Regular')),
              const SizedBox(height: 10),
              Padding(
                  padding: const EdgeInsets.only(bottom: 2.0), // Align amount.
                  child: Text('\$$costDifference', style: dark))
            ],
          ),
        ],
      ),
      const SizedBox(height: 30),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FlatIconButton(
            label: 'Confirm & Pay',
            color: buttonColor,
            textColor: Colors.white,
            onTap: onBillChanged,
            elevation: 8,
          ),
        ],
      ),
    ];
  }

  Widget _yearlyBill(TextStyle light, TextStyle dark, Color buttonColor) {
    final plan = subscription.billing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${plan.name.capsFirst} bill\t',
                style: light,
              ),
              TextSpan(
                text: '\$${subscription?.currentCost ?? '-'}',
                style: dark,
              ),
            ],
          ),
        ),
        if (updatingCC) ...[
          const SizedBox(height: 30),
          FlatIconButton(
            label: 'Update',
            color: buttonColor,
            textColor: Colors.white,
            onTap: onBillChanged,
            elevation: 8,
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          if (diff == 0) _yearlyBill(lightGreyText, darkGreyText, buttonColor),
          if (diff > 0) ..._debit(lightGreyText, darkGreyText, buttonColor),
          if (diff < 0) ..._credit(lightGreyText, darkGreyText, buttonColor),
        ],
      ),
    );
  }
}

class PaymentMethod extends StatefulWidget {
  final PlanSubscriptionPackage sub;
  final BoolCallback onUseSaved;

  const PaymentMethod(
    this.sub, {
    @required this.onUseSaved,
    Key key,
  }) : super(key: key);

  @override
  _MethodState createState() => _MethodState();
}

class _MethodState extends State<PaymentMethod> {
  bool _useSaved = true;

  void _changeView(bool useSaved) {
    setState(() {
      _useSaved = useSaved;
      widget.onUseSaved(useSaved);
    });
  }

  Widget _nextPayment(CustomerInfo info, Color iconColor, TextStyles styles) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TintedIcon(
            icon: PackedIcon.settingsSmall /*TODO: PackedIcon.date*/,
            color: iconColor),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: 'Next payment due: ',
                  style: styles.hierarchyTabHovered
                      .copyWith(fontSize: 13, height: 1.4)),
              TextSpan(
                text: info.nextDue,
                style: styles.fileGreyTextLarge.copyWith(
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _savedInfo(CustomerInfo info) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    final colors = theme.colors;

    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TintedIcon(
              icon: PackedIcon.cardchip /*TODO: PackedIcon.card*/,
              color: colors.commonButtonTextColor,
            ),
            const SizedBox(width: 10),
            Text(
              info.cardDescription,
              style:
                  styles.fileGreyTextLarge.copyWith(fontSize: 13, height: 1.4),
            ),
            const Spacer(),
            UnderlineTextButton(
              text: 'Change',
              onPressed: () => _changeView(false),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _nextPayment(info, colors.commonButtonTextColor, styles)
      ],
    );
  }

  Widget _cardInput(CustomerInfo info) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    final colors = theme.colors;
    return Column(
      children: [
        CreditCardForm(
            sub: widget.sub,
            trailingButtonBuilder: (_) => UnderlineTextButton(
                  text: 'Use saved card instead',
                  onPressed: () => _changeView(true),
                )),
        const SizedBox(height: 30),
        _nextPayment(info, colors.commonButtonTextColor, styles)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final streamId = widget.sub.team.ownerId;
    return ValueStreamBuilder<CustomerInfo>(
      stream: Plumber().getStream<CustomerInfo>(streamId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SettingsPanelSection(
            label: 'Payment',
            contents: (ctx) => _useSaved
                ? _savedInfo(snapshot.data)
                : _cardInput(snapshot.data),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
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
      RiveTextField(
        initialValue: sub.cardNumber,
        formatters: <TextInputFormatter>[
          WhitelistingTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
          CardNumberFormatter()
        ],
        hintText: '0000 0000 0000 0000',
        onChanged: (cardNumber) => sub.cardNumber = cardNumber,
        errorText: sub.cardValidationError,
      )
    ]);
  }

  Widget _creditCardDetails(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;

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
              RiveTextField(
                initialValue: sub.ccv,
                formatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                hintText: '3-4 digits',
                onChanged: (ccv) => sub.ccv = ccv,
                errorText: sub.ccvError,
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
              RiveTextField(
                initialValue: sub.expiration,
                formatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  DateTextInputFormatter(),
                  DateTextRegexCheck()
                ],
                hintText: 'MM/YY',
                onChanged: (expiration) => sub.expiration = expiration,
                errorText: sub.expirationError,
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
              RiveTextField(
                initialValue: sub.zip,
                formatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                hintText: '90210',
                onChanged: (zip) => sub.zip = zip,
                errorText: sub.zipError,
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
