import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/rive_text_field.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/underline_text_button.dart';
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
  PlanSubscriptionPackage _plan;
  AnimationController _controller;
  bool _usingSavedCC = true;

  bool get isBasic => _plan?.option == TeamsOption.basic;
  bool get isPremium => _plan?.option == TeamsOption.premium;

  @override
  void initState() {
    // Fetch current team billing data from the backend.
    PlanSubscriptionPackage.fetchData(widget.api, widget.team).then(
      (value) => setState(
        () {
          _plan = value;
          _controller.value = _plan.option == TeamsOption.basic ? 1 : 0;

          // // Toggle upon receiving the new value.
          // _toggleController();

          // Listen for upcoming changes.
          _plan.addListener(_onSubChange);
        },
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    super.initState();
  }

  void _onSubChange() => setState(_toggleController);

  Future<void> _onBillChanged() async {
    if (await _plan.submitChanges(!_usingSavedCC)) {
      setState(() {
        // Go back to previous view.
        _usingSavedCC = true;
      });
    }
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
    _plan.dispose(); // Cleans up listeners.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_plan == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    final labelLookup = costLookup[_plan?.billing];
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
                        value: _plan?.billing ?? BillingFrequency.monthly,
                        toLabel: (option) => describeEnum(option).capsFirst,
                        change: (billing) => _plan.billing = billing,
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
                            onTap: () => _plan.option = TeamsOption.basic,
                            isSelected: isBasic,
                            highlight: animationValue,
                            showRadio: true,
                          ),
                          const SizedBox(width: 30),
                          SubscriptionChoice(
                            label: 'Org',
                            disabled: true,
                            costLabel: '${labelLookup[TeamsOption.premium]}',
                            description: ''
                                'Create sub-teams with centralized '
                                'billing',
                            onTap: () => _plan.option = TeamsOption.premium,
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
          _plan,
          _usingSavedCC,
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
          plan: _plan,
          onBillChanged: _onBillChanged,
          updatingCC: !_usingSavedCC,
        ),
      ],
    );
  }
}

class BillCalculator extends StatefulWidget {
  final VoidCallback onBillChanged;
  final PlanSubscriptionPackage plan;
  final bool updatingCC;

  const BillCalculator({
    this.plan,
    this.updatingCC,
    this.onBillChanged,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BillState();
}

class _BillState extends State<BillCalculator> {
  bool _processingPayment = false;

  BillingFrequency get billingPlan => widget.plan.billing;

  @override
  void initState() {
    var plan = widget.plan;
    _processingPayment = plan.processing;
    plan.addListener(_handleProcessing);
    super.initState();
  }

  @override
  void dispose() {
    widget.plan.removeListener(_handleProcessing);
    super.dispose();
  }

  void _handleProcessing() {
    if (_processingPayment == widget.plan.processing) {
      return;
    }

    setState(() {
      _processingPayment = widget.plan.processing;
    });
  }

  Widget _nextCharge(TextStyle light, TextStyle dark) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'Starting ', style: light),
          TextSpan(
            text: widget.plan.nextDue,
            style: dark.copyWith(fontFamily: 'Roboto-Regular'),
          ),
          TextSpan(text: ' your will be billed monthly', style: light)
        ],
      ),
    );
  }

  List<Widget> _credit() {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;

    final lightGreyText = textStyles.loginText.copyWith(height: 1.6);
    final darkGreyText = textStyles.notificationTitle.copyWith(height: 1.6);

    return [
      _nextCharge(lightGreyText, darkGreyText),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('New ${billingPlan.name} bill', style: lightGreyText),
              const SizedBox(height: 10),
              Text('Pay now', style: lightGreyText),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${widget.plan.calculatedCost}',
                style: darkGreyText.copyWith(fontFamily: 'Roboto-Regular'),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0), // Align amount.
                child: Text(
                  '\$0',
                  style: darkGreyText.copyWith(fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ],
      ),
      const SizedBox(height: 25),
      FlatIconButton(
        label: 'Confirm',
        color:
            _processingPayment ? colors.commonLightGrey : colors.commonDarkGrey,
        textColor: Colors.white,
        onTap: widget.onBillChanged,
        elevation: _processingPayment ? 0 : 8,
      ),
    ];
  }

  List<Widget> _debit() {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;
    final lightGreyText = textStyles.loginText.copyWith(height: 1.6);
    final darkGreyText = textStyles.notificationTitle.copyWith(height: 1.6);

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('New ${billingPlan.name} bill', style: lightGreyText),
              const SizedBox(height: 10),
              Text('Pay now (prorated)', style: lightGreyText)
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${widget.plan.calculatedCost}',
                style: darkGreyText.copyWith(
                  fontFamily: 'Roboto-Regular',
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0), // Align amount.
                child: Text(
                  '\$${widget.plan.costDifference}',
                  style: darkGreyText,
                ),
              )
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
            color: _processingPayment
                ? colors.commonLightGrey
                : colors.commonDarkGrey,
            textColor: Colors.white,
            onTap: widget.onBillChanged,
            elevation: _processingPayment ? 0 : 8,
          ),
        ],
      ),
    ];
  }

  Widget _yearlyBill() {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;

    final lightGreyText = textStyles.loginText.copyWith(height: 1.6);
    final darkGreyText = textStyles.notificationTitle.copyWith(height: 1.6);

    final billingPlan = widget.plan.billing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${billingPlan.name.capsFirst} bill\t',
                style: lightGreyText,
              ),
              TextSpan(
                text: '\$${widget.plan?.currentCost ?? '-'}',
                style: darkGreyText,
              ),
            ],
          ),
        ),
        if (widget.updatingCC) ...[
          const SizedBox(height: 30),
          FlatIconButton(
            label: 'Update',
            color: _processingPayment
                ? colors.commonLightGrey
                : colors.commonDarkGrey,
            textColor: Colors.white,
            onTap: widget.onBillChanged,
            elevation: _processingPayment ? 0 : 8,
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plan?.currentCost == null) {
      return const SizedBox();
    }
    final diff = widget.plan.costDifference;

    return SettingsPanelSection(
      label: 'Bill',
      contents: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (diff == 0) _yearlyBill(),
          if (diff > 0) ..._debit(),
          if (diff < 0) ..._credit(),
        ],
      ),
    );
  }
}

class PaymentMethod extends StatefulWidget {
  final PlanSubscriptionPackage plan;
  final bool useSaved;
  final BoolCallback onUseSaved;

  const PaymentMethod(
    this.plan,
    this.useSaved, {
    @required this.onUseSaved,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MethodState();
}

class _MethodState extends State<PaymentMethod> {
  String _cardDescription;
  String _nextDue;

  @override
  void initState() {
    // Get the values if they're already available.
    _onCardChange();
    // Setup a listener.
    widget.plan.addListener(_onCardChange);
    super.initState();
  }

  void _onCardChange() {
    var sub = widget.plan;
    if (_cardDescription == sub.cardDescription && _nextDue == sub.nextDue) {
      return;
    }

    setState(() {
      _cardDescription = sub.cardDescription;
      _nextDue = sub.nextDue;
    });
  }

  @override
  void dispose() {
    widget.plan.removeListener(_onCardChange);
    super.dispose();
  }

  Widget _nextPayment(Color iconColor, TextStyles styles) {
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
                text: _nextDue,
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

  Widget _savedInfo(RiveThemeData theme) {
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
              _cardDescription,
              style:
                  styles.fileGreyTextLarge.copyWith(fontSize: 13, height: 1.4),
            ),
            const Spacer(),
            UnderlineTextButton(
              text: 'Change',
              onPressed: () => widget.onUseSaved(false),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _nextPayment(colors.commonButtonTextColor, styles)
      ],
    );
  }

  Widget _cardInput(RiveThemeData theme) {
    final styles = theme.textStyles;
    final colors = theme.colors;
    return Column(
      children: [
        CreditCardForm(
            sub: widget.plan,
            trailingButtonBuilder: (_) => UnderlineTextButton(
                  text: 'Use saved card instead',
                  onPressed: widget.plan.processing
                      ? null
                      : () => widget.onUseSaved(true),
                )),
        const SizedBox(height: 30),
        _nextPayment(colors.commonButtonTextColor, styles)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    if (_cardDescription == null || _nextDue == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SettingsPanelSection(
      label: 'Payment',
      contents: (ctx) =>
          widget.useSaved ? _savedInfo(theme) : _cardInput(theme),
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
