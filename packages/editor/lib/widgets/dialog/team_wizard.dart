import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';

import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/gradient_border.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

const billingPolicyUrl =
    'https://docs.2dimensions.com/rive-help-center/get-started/fair-billing-policy';

Future<T> showTeamWizard<T>({BuildContext context}) {
  return showRiveDialog(
      context: context,
      builder: (context) {
        return Wizard();
      });
}

String capsFirst(String input) => input[0].toUpperCase() + input.substring(1);

/// The subscription frequency options
enum BillingFrequency { yearly, monthly }

/// The subscription team option
enum TeamsOption { basic, premium }

/// The active wizard panel
enum WizardPanel { one, two }

/// Data class for tracking data in the team subscription widget
class TeamSubscriptionPackage with ChangeNotifier {
  /// Team name
  String _name;
  String get name => _name;
  set name(String value) {
    _name = value;
    notifyListeners();
  }

  /// Team subscription freuqency
  BillingFrequency _billing = BillingFrequency.yearly;
  BillingFrequency get billing => _billing;
  set billing(BillingFrequency value) {
    _billing = value;
    notifyListeners();
  }

  /// The teams option
  TeamsOption _option;
  TeamsOption get option => _option;
  set option(TeamsOption value) {
    if (isNameValid) {
      _option = value;
    }
    notifyListeners();
  }

  /// Credit card number
  String _cardNumber;
  String get cardNumber => _cardNumber;
  set cardNumber(String value) {
    _cardNumber = value;
    notifyListeners();
  }

  /// Credit card security number
  String _ccv;
  String get ccv => _ccv;
  set ccv(String value) {
    _ccv = value;
    notifyListeners();
  }

  /// Credt card expiration date
  String _expiration;
  String get expiration => _expiration;
  set expiration(String value) {
    _expiration = value;
    notifyListeners();
  }

  /// Credit card billing zip code
  String _zip;
  String get zip => _zip;
  set zip(String value) {
    _zip = value;
    notifyListeners();
  }

  // User friendly Name validation error messages
  String _nameValidationError;
  String get nameValidationError => _nameValidationError;

  /// Validates the team name
  bool get isNameValid {
    /// Minimum length for a valid team name.
    const _minTeamNameLength = 4;

    /// Regex for valid team names
    final _legalNameMatch = RegExp(r'^[A-Za-z0-9]+$');

    if (name == null || name == '') {
      _nameValidationError = 'Please enter a valid team name.';
      return false;
    }

    if (name.length < _minTeamNameLength) {
      _nameValidationError = 'At least $_minTeamNameLength characters';
      return false;
    }

    if (!_legalNameMatch.hasMatch(name)) {
      _nameValidationError = 'No spaces or symbols';
      return false;
    }
    _nameValidationError = null;
    return true;
  }

  /// Validate the team options
  bool get isOptionValid => _option != null;

  /// Validate the credit card
  bool get isCardNrValid {
    if (_cardNumber == null) {
      return false;
    }

    if (!RegExp(r'^[0-9]{16}$').hasMatch(_cardNumber)) {
      return false;
    }
    return true;
  }

  /// Step 1 is valid; safe to proceed to step 2
  bool get isStep1Valid => isNameValid && isOptionValid;

  /// Step 2 is valid; safe to attempt team creation
  bool get isStep2Valid => isNameValid && isOptionValid && isCardNrValid;
}

/// The main panel for holding the team wizard views
class Wizard extends StatefulWidget {
  @override
  _WizardState createState() => _WizardState();
}

class _WizardState extends State<Wizard> {
  TeamSubscriptionPackage _sub;
  WizardPanel activePanel = WizardPanel.one;

  @override
  void initState() {
    _sub = TeamSubscriptionPackage();
    // Listen for changes to the package and handle appropriately
    _sub.addListener(() {
      // _sub.attemptProgress();
      // Show the appropriate panel depending on the sub state
      setState(() =>
          activePanel = _sub.isStep1Valid ? WizardPanel.two : WizardPanel.one);
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return activePanel == WizardPanel.one
        ? TeamWizardPanelOne(_sub)
        : TeamWizardPanelTwo(_sub);
  }
}

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
                      toLabel: (option) => capsFirst(describeEnum(option)),
                      contentPadding: const EdgeInsets.only(bottom: 3),
                      change: (billing) => sub.billing = billing,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: sub.isNameValid
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

class TeamWizardPanelTwo extends StatelessWidget {
  final TeamSubscriptionPackage sub;

  const TeamWizardPanelTwo(this.sub, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final billingOptions = [
      BillingFrequency.yearly,
      BillingFrequency.monthly,
    ];
    final teamOptions = [
      TeamsOption.basic,
      TeamsOption.premium,
    ];

    return SizedBox(
      width: 452,
      height: 505,
      child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(children: [
            Row(
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 4, right: 20),
                    child: SizedBox(
                      width: 7,
                      height: 14,
                      child: CustomPaint(painter: LeftArrow()),
                    ),
                  ),
                  // Little hacky, but nulling the option will cause the wizard
                  // to jump back to the first step
                  onTap: () => sub.option = null,
                ),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    sub.name,
                    textAlign: TextAlign.left,
                    // textAlignVertical: TextAlignVertical.center,
                    style: textStyles.fileGreyTextLarge,
                  ),
                )),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: SizedBox(
                    width: 71,
                    child: ComboBox<TeamsOption>(
                      popupWidth: 100,
                      sizing: ComboSizing.content,
                      underline: true,
                      underlineColor: colors.inputUnderline,
                      valueColor: textStyles.fileGreyTextLarge.color,
                      options: teamOptions,
                      value: sub.option,
                      toLabel: (option) => capsFirst(describeEnum(option)),
                      contentPadding: const EdgeInsets.only(bottom: 3),
                      change: (option) => sub.option = option,
                    ),
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
                      options: billingOptions,
                      value: sub.billing,
                      toLabel: (option) => capsFirst(describeEnum(option)),
                      contentPadding: const EdgeInsets.only(bottom: 3),
                      change: (billing) => sub.billing = billing,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 30, bottom: 15),
              padding: const EdgeInsets.all(31),
              width: 392,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(width: 1.0, color: const Color(0xFFE3E3E3)),
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(children: [
                    Container(
                      width: 46,
                      height: 34,
                      child: CustomPaint(
                        painter: Chip(),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 58,
                          height: 34,
                          child: CustomPaint(
                            painter: MasterCard(),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 34, bottom: 12),
                    child: Text(
                      'Card Number',
                      style: textStyles.inspectorPropertyLabel,
                    ),
                  ),
                  TextFormField(
                    textAlign: TextAlign.left,
                    textAlignVertical: TextAlignVertical.center,
                    style: textStyles.inspectorPropertyLabel,
                    initialValue: sub.cardNumber,
                    decoration: InputDecoration(
                      isDense: true,
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: colors.inputUnderline, width: 2)),
                      hintText: '0000 0000 0000 0000',
                      //errorText:
                      //    sub.isCardNrValid ? null : 'Invalid card number',
                      hintStyle:
                          textStyles.textFieldInputHint.copyWith(fontSize: 13),
                      errorStyle: textStyles.textFieldInputValidationError,
                      contentPadding: const EdgeInsets.only(bottom: 3),
                      filled: true,
                      hoverColor: Colors.transparent,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (cardNumber) => sub.cardNumber = cardNumber,
                  ),
                  // CVV
                  Padding(
                      padding: const EdgeInsets.only(top: 27),
                      child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            SizedBox(
                              width: 90,
                              child: Text(
                                'CVC/CVV',
                                style: textStyles.inspectorPropertyLabel,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 30, right: 30),
                              child: SizedBox(
                                  width: 90,
                                  child: Text(
                                    'Expiration',
                                    style: textStyles.inspectorPropertyLabel,
                                  )),
                            ),
                            SizedBox(
                                width: 88,
                                child: Text(
                                  'Zip',
                                  style: textStyles.inspectorPropertyLabel,
                                )),
                          ])),

                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            textAlign: TextAlign.left,
                            textAlignVertical: TextAlignVertical.center,
                            style: textStyles.inspectorPropertyLabel,
                            initialValue: sub.ccv,
                            decoration: InputDecoration(
                              isDense: true,
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: colors.inputUnderline, width: 2)),
                              hintText: '3-4 digits',
                              hintStyle: textStyles.textFieldInputHint
                                  .copyWith(fontSize: 13),
                              errorStyle:
                                  textStyles.textFieldInputValidationError,
                              contentPadding: const EdgeInsets.only(bottom: 3),
                              filled: true,
                              hoverColor: Colors.transparent,
                              fillColor: Colors.transparent,
                            ),
                            onChanged: (ccv) => sub.ccv = ccv,
                          ),
                        ),
                        // Expiry date
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: SizedBox(
                              width: 90,
                              child: TextFormField(
                                textAlign: TextAlign.left,
                                textAlignVertical: TextAlignVertical.center,
                                style: textStyles.inspectorPropertyLabel,
                                initialValue: sub.expiration,
                                decoration: InputDecoration(
                                  isDense: true,
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: colors.inputUnderline,
                                          width: 2)),
                                  hintText: 'MM/YY',
                                  hintStyle: textStyles.textFieldInputHint
                                      .copyWith(fontSize: 13),
                                  errorStyle:
                                      textStyles.textFieldInputValidationError,
                                  contentPadding:
                                      const EdgeInsets.only(bottom: 3),
                                  filled: true,
                                  hoverColor: Colors.transparent,
                                  fillColor: Colors.transparent,
                                ),
                                onChanged: (expiration) =>
                                    sub.expiration = expiration,
                              )),
                        ),
                        // ZIP code
                        SizedBox(
                            width: 88,
                            child: TextFormField(
                              textAlign: TextAlign.left,
                              textAlignVertical: TextAlignVertical.center,
                              style: textStyles.inspectorPropertyLabel,
                              initialValue: sub.zip,
                              decoration: InputDecoration(
                                isDense: true,
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: colors.inputUnderline,
                                        width: 2)),
                                hintText: '90210',
                                hintStyle: textStyles.textFieldInputHint
                                    .copyWith(fontSize: 13),
                                errorStyle:
                                    textStyles.textFieldInputValidationError,
                                contentPadding:
                                    const EdgeInsets.only(bottom: 3),
                                filled: true,
                                hoverColor: Colors.transparent,
                                fillColor: Colors.transparent,
                              ),
                              onChanged: (zip) => sub.zip = zip,
                            )),
                      ],
                    ),
                  )
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
            )),
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(
                  'Due now (1 user)',
                  style: textStyles.tooltipDisclaimer,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('\$168', style: textStyles.tooltipBold),
                )
              ]),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                // child: FlatButton(child: Text('stff'), onPressed: () {}),
                child: Container(
                  width: 181,
                  child: FlatIconButton(
                    mainAxisAlignment: MainAxisAlignment.center,
                    label: 'Create Team & Pay',
                    color: colors.buttonDark,
                    textColor: Colors.white,
                    // elevated: _hover,
                  ),
                ),
              ),
            )
          ])),
    );
  }
}

class LeftArrow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..isAntiAlias = true;
    var path = Path();
    canvas.save();
    path.moveTo(size.width, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(size.width, size.height);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MasterCard extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFE3E3E3)
      ..isAntiAlias = true;

    Rect rect = Rect.fromLTWH(0, 0, size.height, size.height);
    Rect rect2 =
        Rect.fromLTWH(size.width - size.height, 0, size.height, size.height);
    // canvas.drawOval(rect, paint);
    canvas.drawArc(rect, pi / 4, pi * 3 / 2, false, paint);
    canvas.drawOval(rect2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class Chip extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFE3E3E3)
      ..isAntiAlias = true;
    Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(5)));
    path.moveTo(0, size.height / 3);
    path.lineTo(size.width / 3, size.height / 3);
    path.moveTo(0, size.height * 2 / 3);
    path.lineTo(size.width / 3, size.height * 2 / 3);
    path.moveTo(size.width * 2 / 3, size.height / 3);
    path.lineTo(size.width, size.height / 3);
    path.moveTo(size.width * 2 / 3, size.height * 2 / 3);
    path.lineTo(size.width, size.height * 2 / 3);

    path.moveTo(size.width * 4 / 12, 0);
    path.lineTo(size.width * 5 / 12, size.height * 1 / 6);
    path.lineTo(size.width * 4 / 12, size.height * 2 / 6);
    path.lineTo(size.width * 5 / 12, size.height * 3 / 6);
    path.lineTo(size.width * 4 / 12, size.height * 4 / 6);
    path.lineTo(size.width * 5 / 12, size.height * 5 / 6);
    path.lineTo(size.width * 4 / 12, size.height * 6 / 6);

    path.moveTo(size.width * 8 / 12, 0);
    path.lineTo(size.width * 7 / 12, size.height * 1 / 6);
    path.lineTo(size.width * 8 / 12, size.height * 2 / 6);
    path.lineTo(size.width * 7 / 12, size.height * 3 / 6);
    path.lineTo(size.width * 8 / 12, size.height * 4 / 6);
    path.lineTo(size.width * 7 / 12, size.height * 5 / 6);
    path.lineTo(size.width * 8 / 12, size.height * 6 / 6);

    path.moveTo(size.width * 5 / 12, size.height * 1 / 12);
    path.lineTo(size.width * 7 / 12, size.height * 1 / 12);

    path.moveTo(size.width * 5 / 12, size.height * 11 / 12);
    path.lineTo(size.width * 7 / 12, size.height * 11 / 12);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
