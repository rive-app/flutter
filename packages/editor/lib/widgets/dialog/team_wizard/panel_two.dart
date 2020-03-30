import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_package.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:url_launcher/url_launcher.dart';

/// Second and final panel in the teams wizard
class TeamWizardPanelTwo extends StatelessWidget {
  final TeamSubscriptionPackage sub;

  const TeamWizardPanelTwo(this.sub, {Key key}) : super(key: key);

  Widget _header(BuildContext context) {
    // final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    return Row(
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.only(right: 20),
            child: TintedIcon(
              icon: 'back',
              color: Colors.black,
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
            child: _optionsComboBox(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: SizedBox(
            width: 71,
            child: _billingComboBox(context),
          ),
        ),
      ],
    );
  }

  Widget _optionsComboBox(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final teamOptions = [TeamsOption.basic, TeamsOption.premium];

    return ComboBox<TeamsOption>(
      popupWidth: 100,
      sizing: ComboSizing.content,
      underline: true,
      underlineColor: colors.inputUnderline,
      valueColor: textStyles.fileGreyTextLarge.color,
      options: teamOptions,
      value: sub.option,
      toLabel: (option) => describeEnum(option).capsFirst,
      contentPadding: const EdgeInsets.only(bottom: 3),
      change: (option) => sub.option = option,
    );
  }

  Widget _billingComboBox(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final billingOptions = [BillingFrequency.yearly, BillingFrequency.monthly];

    return ComboBox<BillingFrequency>(
      popupWidth: 100,
      sizing: ComboSizing.content,
      underline: true,
      underlineColor: colors.inputUnderline,
      valueColor: textStyles.fileGreyTextLarge.color,
      options: billingOptions,
      value: sub.billing,
      toLabel: (option) => describeEnum(option).capsFirst,
      contentPadding: const EdgeInsets.only(bottom: 3),
      change: (billing) => sub.billing = billing,
    );
  }

  Widget _creditCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30, bottom: 15),
      padding: const EdgeInsets.all(31),
      width: 392,
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(width: 1.0, color: const Color(0xFFE3E3E3)),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          // Chip and Mastercard gfx
          _cardGfx(context),
          // Credit card number
          _creditCardNumber(context),
          // Credit card details
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: _cardDetails(context),
          ),
        ],
      ),
    );
  }

  Widget _cardGfx(BuildContext context) {
    final colors = RiveTheme.of(context).colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TintedIcon(
          icon: 'card_chip',
          color: colors.buttonLight,
        ),
        TintedIcon(
          icon: 'card_logo',
          color: colors.buttonLight,
        ),
      ],
    );
  }

  Widget _creditCardNumber(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          inputFormatters: <TextInputFormatter>[
            WhitelistingTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            CardNumberFormatter()
          ],
          decoration: InputDecoration(
            isDense: true,
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.inputUnderline, width: 2)),
            hintText: '0000 0000 0000 0000',
            //errorText:
            //    sub.isCardNrValid ? null : 'Invalid card number',
            hintStyle: textStyles.textFieldInputHint.copyWith(fontSize: 13),
            errorStyle: textStyles.textFieldInputValidationError,
            contentPadding: const EdgeInsets.only(bottom: 3),
            filled: true,
            hoverColor: Colors.transparent,
            fillColor: Colors.transparent,
          ),
          onChanged: (cardNumber) => sub.cardNumber = cardNumber,
        ),
      ],
    );
  }

  Widget _cardDetails(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // CVV
        SizedBox(
          width: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CVC/CVV',
                style: textStyles.inspectorPropertyLabel,
              ),
              const SizedBox(height: 12),
              TextFormField(
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: textStyles.inspectorPropertyLabel,
                initialValue: sub.ccv,
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colors.inputUnderline, width: 2)),
                  hintText: '3-4 digits',
                  hintStyle:
                      textStyles.textFieldInputHint.copyWith(fontSize: 13),
                  errorStyle: textStyles.textFieldInputValidationError,
                  contentPadding: const EdgeInsets.only(bottom: 3),
                  filled: true,
                  hoverColor: Colors.transparent,
                  fillColor: Colors.transparent,
                ),
                onChanged: (ccv) => sub.ccv = ccv,
              ),
            ],
          ),
        ),
        // Expiration
        SizedBox(
          width: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expiration',
                style: textStyles.inspectorPropertyLabel,
              ),
              const SizedBox(height: 12),
              TextFormField(
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: textStyles.inspectorPropertyLabel,
                initialValue: sub.expiration,
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
                  hintText: 'MM/YY',
                  hintStyle:
                      textStyles.textFieldInputHint.copyWith(fontSize: 13),
                  errorStyle: textStyles.textFieldInputValidationError,
                  contentPadding: const EdgeInsets.only(bottom: 3),
                  filled: true,
                  hoverColor: Colors.transparent,
                  fillColor: Colors.transparent,
                ),
                onChanged: (expiration) => sub.expiration = expiration,
              ),
            ],
          ),
        ),
        // Zip
        SizedBox(
          width: 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zip',
                style: textStyles.inspectorPropertyLabel,
              ),
              const SizedBox(height: 12),
              TextFormField(
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: textStyles.inspectorPropertyLabel,
                initialValue: sub.zip,
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colors.inputUnderline, width: 2)),
                  hintText: '90210',
                  hintStyle:
                      textStyles.textFieldInputHint.copyWith(fontSize: 13),
                  errorStyle: textStyles.textFieldInputValidationError,
                  contentPadding: const EdgeInsets.only(bottom: 3),
                  filled: true,
                  hoverColor: Colors.transparent,
                  fillColor: Colors.transparent,
                ),
                onChanged: (zip) => sub.zip = zip,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _billingPolicy(BuildContext context) {
    final textStyles = RiveTheme.of(context).textStyles;
    return RichText(
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
      ),
    );
  }

  Widget _cost(BuildContext context) {
    final textStyles = RiveTheme.of(context).textStyles;

    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(
          'Due now (1 user)',
          style: textStyles.tooltipDisclaimer,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text('\$${sub.calculatedCost}', style: textStyles.tooltipBold),
        )
      ]),
    );
  }

  Widget _createTeamButton(BuildContext context) {
    final colors = RiveTheme.of(context).colors;

    return Align(
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
            onTap: () {
              sub.submit(context, RiveContext.of(context).api);
            },
            // elevated: _hover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 452,
      height: 505,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            _header(context),
            _creditCard(context),
            _billingPolicy(context),
            _cost(context),
            _createTeamButton(context),
          ],
        ),
      ),
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    final StringBuffer newText = StringBuffer();
    int writeIndex = 0;
    if (newTextLength > 4) {
      newText.write(newValue.text.substring(0, 4));
      newText.write(' ');
      writeIndex += 4;
      selectionIndex += 1;
    }
    if (newTextLength > 8) {
      newText.write(newValue.text.substring(4, 8));
      newText.write(' ');
      writeIndex += 4;
      selectionIndex += 1;
    }
    if (newTextLength > 12) {
      newText.write(newValue.text.substring(8, 12));
      newText.write(' ');
      writeIndex += 4;
      selectionIndex += 1;
    }
    newText.write(newValue.text.substring(writeIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    final StringBuffer newText = StringBuffer();
    int writeIndex = 0;
    if (newTextLength > 2) {
      newText.write(newValue.text.substring(0, 2));
      newText.write('/');
      writeIndex += 2;
      selectionIndex += 1;
    }
    newText.write(newValue.text.substring(writeIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class DateTextRegexCheck extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var regex = RegExp(r'^(0[1-9]*|1[012]*|$)/*\d*\d*');
    var match = regex.firstMatch(newValue.text);
    if (match != null && match.end == newValue.text.length) {
      return newValue;
    }
    return oldValue;
  }
}
