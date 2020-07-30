import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/currency.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/common/rive_radio.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:utilities/utilities.dart';

typedef void BoolCallback(bool flag);

class PlanSettings extends StatefulWidget {
  final Team team;
  final RiveApi api;
  const PlanSettings(this.team, this.api);

  @override
  State<StatefulWidget> createState() => _PlanState();
}

enum RetryPaymentState { notApplicable, success, failure }

class _PlanState extends State<PlanSettings>
    with SingleTickerProviderStateMixin {
  PlanSubscriptionPackage _plan;
  AnimationController _controller;
  bool _usingSavedCC = true;
  RetryPaymentState _retryState = RetryPaymentState.notApplicable;
  // Flag to activate the flow for canceling the current plan:
  bool _cancelFlow = false;

  bool get isBasic => _plan?.option == TeamsOption.basic;
  bool get isPremium => _plan?.option == TeamsOption.premium;

  @override
  void initState() {
    _refreshData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    super.initState();
  }

  void _refreshData() {
    // Fetch current team billing data from the backend.
    PlanSubscriptionPackage.fetchData(widget.api, widget.team).then((value) {
      // Don't call if already disposed.
      if (mounted) {
        setState(
          () {
            var oldPlan = _plan;
            _plan = value;
            _controller.value = _plan.option == TeamsOption.basic ? 1 : 0;

            // Toggle upon receiving the new value.
            // _toggleController();
            _plan.addListener(_onSubChange);
            oldPlan?.dispose();
          },
        );
      }
    });
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

  Future<void> _onTryAgain() async {
    var success = await _plan.retryPayment(!_usingSavedCC);
    setState(() {
      // Go back to previous view.
      if (success) {
        _retryState = RetryPaymentState.success;
      } else {
        _retryState = RetryPaymentState.failure;
      }
    });
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
    _plan?.dispose(); // Cleans up listeners.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_plan == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cancelFlow) {
      return _CancelPlan(
        plan: _plan,
        onDone: (didChange) => setState(() {
          if (didChange) {
            _plan?.dispose();
            _plan = null;
            _refreshData();
          }
          _cancelFlow = false;
        }),
      );
    } else {
      final theme = RiveTheme.of(context);
      final colors = theme.colors;
      final textStyles = theme.textStyles;
      final labelLookup = costLookup[_plan?.billing];
      final isPlanCanceled = _plan.isCanceled;

      return ListView(
        padding: const EdgeInsets.all(30),
        physics: const ClampingScrollPhysics(),
        children: [
          SettingsPanelSection(
            label: 'Plan',
            labelExtra: isPlanCanceled ? ' (canceled)' : null,
            subLabel: (isPlanCanceled && _plan.isActive)
                ? 'Expires ${_plan.nextDueDescription}'
                : null,
            secondaryColor: colors.accentMagenta,
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
                          underline: !isPlanCanceled,
                          chevron: !isPlanCanceled,
                          underlineColor: colors.inputUnderline,
                          valueColor: textStyles.fileGreyTextLarge.color,
                          options: BillingFrequency.values,
                          value: _plan?.billing ?? BillingFrequency.monthly,
                          toLabel: (option) => describeEnum(option).capsFirst,
                          change: (billing) => _plan.billing = billing,
                          disabled: isPlanCanceled ||
                              _plan.status == TeamStatus.failedPayment,
                        ),
                      ),
                      const Spacer(),
                      if (!isPlanCanceled)
                        UnderlineTextButton(
                          text: 'Cancel Plan',
                          onPressed: () => setState(() {
                            _cancelFlow = true;
                          }),
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
                              label: 'Studio',
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
          BillingStatus(
            plan: _plan,
            onBillChanged: isPlanCanceled
                // The button in the widget will reactivate the widget.
                ? () async {
                    if (await _plan.renewPlan(true)) {
                      _refreshData();
                    }
                  }
                : _onBillChanged,
            onTryAgain: _onTryAgain,
            updatingCC: !_usingSavedCC,
            retryState: _retryState,
          ),
        ],
      );
    }
  }
}

class BillingStatus extends StatefulWidget {
  final VoidCallback onBillChanged;
  final VoidCallback onTryAgain;
  final PlanSubscriptionPackage plan;
  final bool updatingCC;
  final RetryPaymentState retryState;

  const BillingStatus({
    this.plan,
    this.updatingCC,
    this.retryState,
    this.onBillChanged,
    this.onTryAgain,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BillState();
}

class _BillState extends State<BillingStatus> {
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
    widget.plan?.removeListener(_handleProcessing);
    super.dispose();
  }

  void _handleProcessing() {
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
            text: widget.plan.nextDueDescription,
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

  Widget _regularBill() {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;

    final successText =
        textStyles.loginText.copyWith(height: 1.6, color: colors.accentBlue);
    final lightGreyText = textStyles.loginText.copyWith(height: 1.6);
    final darkGreyText = textStyles.notificationTitle.copyWith(height: 1.6);

    final billingPlan = widget.plan.billing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.plan.balance < 0)
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Credit\t',
                  style: lightGreyText,
                ),
                TextSpan(
                  text: (widget.plan == null)
                      ? '-'
                      : asDollars(-widget.plan.balance),
                  style: darkGreyText,
                ),
              ],
            ),
          ),
        if (widget.plan.balance > 0)
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Pro rata\t',
                  style: lightGreyText,
                ),
                TextSpan(
                  text: (widget.plan == null)
                      ? '-'
                      : asDollars(widget.plan.balance),
                  style: darkGreyText,
                ),
              ],
            ),
          ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${billingPlan.name.capsFirst} bill\t',
                style: lightGreyText,
              ),
              TextSpan(
                text: (widget.plan == null)
                    ? '-'
                    : asDollars(widget.plan.nextBill),
                style: darkGreyText,
              ),
            ],
          ),
        ),
        if (widget.plan.balance != 0)
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Next Bill Total\t',
                  style: lightGreyText,
                ),
                TextSpan(
                  text: (widget.plan == null)
                      ? '-'
                      : asDollars(
                          max(widget.plan.nextBill + widget.plan.balance, 0)),
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
        ],
        if (widget.retryState == RetryPaymentState.success) ...[
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Success! Thanks for the payment.',
                  style: successText,
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  List<Widget> _retryPayment() {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;

    final errorText =
        textStyles.loginText.copyWith(height: 1.6, color: colors.errorText);
    final lightGreyText = textStyles.loginText.copyWith(height: 1.6);
    final darkGreyText = textStyles.notificationTitle.copyWith(height: 1.6);

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'We weren\'t able to bill your credit card. '
                      'Please update your payment information and try again.',
                  style: lightGreyText,
                )
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Amount due  ',
                  style: lightGreyText,
                ),
                TextSpan(
                  text: asDollars(widget.plan.balance),
                  style: darkGreyText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.retryState == RetryPaymentState.failure)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Looks like something still isn\'t working',
                            style: errorText,
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Drop us a note if you need any help.',
                            style: errorText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.only(left: 17.0),
                child: FlatIconButton(
                  label: 'Try Again',
                  color: _processingPayment
                      ? colors.commonLightGrey
                      : colors.commonDarkGrey,
                  textColor: Colors.white,
                  onTap: widget.onTryAgain,
                  elevation: _processingPayment ? 0 : 8,
                ),
              ),
            ],
          ),
        ],
      )
    ];
  }

  Widget _canceledPlanDue() {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final lightGreyText = textStyles.loginText.copyWith(height: 1.6);
    final darkGreyText = textStyles.notificationTitle.copyWith(height: 1.6);

    if (widget.plan.isActive) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${billingPlan.name.capsFirst} plan',
                style: lightGreyText,
              ),
              Text(
                'Due now',
                style: lightGreyText,
              )
            ],
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${widget.plan.calculatedCost}',
                style: darkGreyText,
              ),
              Padding(
                // Align baseline
                padding: const EdgeInsets.only(bottom: 1),
                child: Text('\$0', style: darkGreyText),
              )
            ],
          ),
        ],
      );
    } else {
      return RichText(
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
      );
    }
  }

  List<Widget> _renewCanceled() {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;
    final plan = widget.plan;
    final lightGreyText = textStyles.loginText.copyWith(height: 1.6);

    return [
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Your plan is canceled, but you can re-activate this team '
                  'and pick up where you left off!',
              style: lightGreyText,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TintedIcon(
            icon: PackedIcon.calendar,
            color: colors.commonButtonTextColor,
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: plan.isActive
                        ? 'Next payment due: '
                        : 'Plan start date: ',
                    style: textStyles.hierarchyTabHovered
                        .copyWith(fontSize: 13, height: 1.4)),
                TextSpan(
                  text: plan.isActive
                      ? plan.nextDueDescription
                      : DateTime.now().shortDescription,
                  style: textStyles.fileGreyTextLarge.copyWith(
                    fontSize: 13,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      const SizedBox(height: 11),
      _canceledPlanDue(),
      const SizedBox(height: 30),
      FlatIconButton(
        label: plan.isActive ? 'Re-activate' : 'Re-activate and pay now',
        color:
            _processingPayment ? colors.commonLightGrey : colors.commonDarkGrey,
        textColor: Colors.white,
        onTap: widget.onBillChanged,
        elevation: _processingPayment ? 0 : 8,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    if (plan?.currentCost == null) {
      return const SizedBox();
    }
    final diff = plan.costDifference;
    if (plan.status == TeamStatus.failedPayment) {
      return SettingsPanelSection(
        label: 'Billing Problem',
        contents: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [..._retryPayment()],
        ),
      );
    } else if (plan.isCanceled) {
      return SettingsPanelSection(
        label: 'Re-activate',
        contents: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _renewCanceled(),
        ),
      );
    } else {
      return SettingsPanelSection(
        label: plan.isCanceled ? 'Re-activate' : 'Bill',
        contents: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (diff == 0) _regularBill(),
            if (diff > 0) ..._debit(),
            if (diff < 0) ..._credit(),
          ],
        ),
      );
    }
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
  bool _lastPaymentFailed;

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
    var lastPaymentFailed = widget.plan.status == TeamStatus.failedPayment;
    if (_cardDescription == sub.cardDescription &&
        _nextDue == sub.nextDueDescription &&
        _lastPaymentFailed == lastPaymentFailed) {
      return;
    }

    setState(() {
      _cardDescription = sub.cardDescription;
      _nextDue = sub.nextDueDescription;
      _lastPaymentFailed = lastPaymentFailed;
    });
  }

  @override
  void dispose() {
    widget.plan?.removeListener(_onCardChange);
    super.dispose();
  }

  Widget _nextPayment(RiveColors colors, TextStyles styles) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TintedIcon(
            icon: PackedIcon.calendar, color: colors.commonButtonTextColor),
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
                    color: _lastPaymentFailed
                        ? colors.errorText
                        : styles.fileGreyTextLarge.color),
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
              icon: PackedIcon.creditcard,
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
        if (!widget.plan.isCanceled) ...[
          const SizedBox(height: 15),
          _nextPayment(colors, styles)
        ]
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
        if (!widget.plan.isCanceled) ...[
          const SizedBox(height: 30),
          _nextPayment(colors, styles)
        ]
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

enum _CancelFlow { canceling, canceled }
enum _Feedback { features, ux, support, runtimes, bugs, expensive }

extension _FeedbackNames on _Feedback {
  String get name => <_Feedback, String>{
        _Feedback.features: 'Missing critical features',
        _Feedback.ux: 'Poor user experience',
        _Feedback.support: 'Poor customer support',
        _Feedback.runtimes: 'Lack of integrations, import options, runtimes',
        _Feedback.bugs: 'Bugs, performance, or stability issues',
        _Feedback.expensive: 'Too expensive',
      }[this];
}

class _CancelPlan extends StatefulWidget {
  const _CancelPlan({
    this.plan,
    this.onDone,
  });

  final PlanSubscriptionPackage plan;
  final ValueChanged<bool> onDone;

  @override
  State<StatefulWidget> createState() => _CancelPlanState();
}

class _CancelPlanState extends State<_CancelPlan> {
  _CancelFlow _flow = _CancelFlow.canceling;
  _Feedback _feedback;
  TapGestureRecognizer _noteRecognizer;
  TextEditingController _feedbackController;

  @override
  void initState() {
    _noteRecognizer = TapGestureRecognizer();
    _noteRecognizer.onTap = _dropNote;
    _feedbackController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _noteRecognizer.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _dropNote() async {
    const url = 'mailto:hello@rive.app';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _onFeedbackChanged(_Feedback value) {
    if (_feedback == value) return;
    setState(() {
      _feedback = value;
    });
  }

  Future<void> _onPlanCanceled() async {
    if (await widget.plan.renewPlan(false)) {
      setState(() {
        _flow = _CancelFlow.canceled;
      });
    }
  }

  Future<void> _sendFeedback() async {
    if (await widget.plan
        .sendFeedback(_feedback.name, _feedbackController.text)) {
      widget.onDone(true);
    }
  }

  Widget _areYouSure(BuildContext context) {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;
    final plan = widget.plan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: textStyles.planText,
            text: 'If you cancel, your team plan will not renew at the next '
                'billing cycle. At that moment, team members will lose'
                ' access to team files. The team plan can be re-activated'
                ' at any time.\n\n',
            children: [
              TextSpan(
                style: textStyles.planDarkText
                    .copyWith(decoration: TextDecoration.underline),
                recognizer: _noteRecognizer,
                text: 'Drop us a note',
              ),
              const TextSpan(
                text: ' if you have any questions, we’re always'
                    ' available to help.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FlatIconButton(
                label: 'No, take me back',
                color: colors.textButtonLight,
                hoverColor: colors.textButtonLightHover,
                textColor: colors.buttonLightText,
                onTap: () => widget.onDone(false),
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FlatIconButton(
                label: 'Yes, cancel my studio plan',
                color: plan.processing
                    ? colors.accentMagenta.withOpacity(0.5)
                    : colors.accentMagenta,
                textColor:
                    plan.processing ? colors.textButtonLight : Colors.white,
                onTap: _onPlanCanceled,
                elevation: plan.processing ? 0 : 8,
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _feedbackForm(BuildContext context) {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;
    final plan = widget.plan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your team plan will not renew at the next billing cycle. '
          'We’d love to know why you canceled and if there’s anything'
          ' we can do to improve.',
          style: textStyles.planText,
        ),
        const SizedBox(height: 24),
        ..._Feedback.values.map(
          (fb) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LabeledRadio<_Feedback>(
              value: fb,
              groupValue: _feedback,
              label: fb.name,
              onChanged: _onFeedbackChanged,
            ),
          ),
        ),
        const SizedBox(height: 14),
        LabeledTextField(
          label: 'Anything else?',
          controller: _feedbackController,
          hintText: 'Your notes...',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FlatIconButton(
                label: 'Skip',
                color: colors.textButtonLight,
                hoverColor: colors.textButtonLightHover,
                textColor: colors.buttonLightText,
                onTap: () => widget.onDone(true),
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FlatIconButton(
                label: 'Send Feedback',
                color: plan.processing || _feedback == null
                    ? colors.buttonDarkDisabled
                    : colors.textButtonDark,
                textColor: Colors.white,
                onTap: _feedback == null ? null : _sendFeedback,
                elevation: plan.processing ? 0 : 8,
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _contents() {
    if (_flow == _CancelFlow.canceling) {
      return SettingsPanelSection(
        label: 'Are you sure you want to cancel?',
        contents: _areYouSure,
      );
    } else {}
    return SettingsPanelSection(
      label: 'Team Canceled',
      contents: _feedbackForm,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(30),
      physics: const ClampingScrollPhysics(),
      children: [_contents()],
    );
  }
}
