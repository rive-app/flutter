import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/rive_text_field.dart';
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
          padding: const EdgeInsets.only(left: 30),
          child: SizedBox(
            width: 71,
            child: _optionsComboBox(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30),
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
    final teamOptions = [TeamsOption.basic];

    return ComboBox<TeamsOption>(
      popupWidth: 100,
      sizing: ComboSizing.sized,
      underline: true,
      underlineColor: colors.inputUnderline,
      valueColor: textStyles.fileGreyTextLarge.color,
      options: teamOptions,
      value: sub.option,
      toLabel: (option) => option.name.capsFirst,
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
      sizing: ComboSizing.sized,
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
      margin: const EdgeInsets.only(top: 30, bottom: 27),
      padding: (sub.ccvError == null &&
              sub.expirationError == null &&
              sub.zipError == null)
          ? const EdgeInsets.all(30)
          : const EdgeInsets.all(30).copyWith(bottom: 10),
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
            padding: sub.cardValidationError == null
                ? const EdgeInsets.only(top: 25)
                : const EdgeInsets.only(top: 5),
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
        RiveTextField(
          onChanged: (cardNumber) => sub.cardNumber = cardNumber,
          enabled: !sub.processing,
          initialValue: sub.cardNumber,
          errorAlignment: MainAxisAlignment.start,
          formatters: <TextInputFormatter>[
            WhitelistingTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            CardNumberFormatter()
          ],
          hintText: '0000 0000 0000 0000',
          errorText: sub.cardValidationError,
        ),
      ],
    );
  }

  Widget _cardDetails(BuildContext context) {
    final textStyles = RiveTheme.of(context).textStyles;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              RiveTextField(
                initialValue: sub.ccv,
                errorAlignment: MainAxisAlignment.start,
                formatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                enabled: !sub.processing,
                onChanged: (ccv) => sub.ccv = ccv,
                hintText: '3-4 digits',
                errorText: sub.ccvError,
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
              RiveTextField(
                onChanged: (expiration) => sub.expiration = expiration,
                enabled: !sub.processing,
                initialValue: sub.expiration,
                errorAlignment: MainAxisAlignment.start,
                formatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  DateTextInputFormatter(),
                  DateTextRegexCheck()
                ],
                hintText: 'MM/YY',
                errorText: sub.expirationError,
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
              RiveTextField(
                onChanged: (zip) => sub.zip = zip,
                enabled: !sub.processing,
                initialValue: sub.zip,
                errorAlignment: MainAxisAlignment.start,
                formatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                hintText: '90210',
                errorText: sub.zipError,
              ),
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
        style: textStyles.tooltipDisclaimer.copyWith(
          // want line height to be 21px
          height: 21 / textStyles.tooltipDisclaimer.fontSize,
        ),
      ),
    );
  }

  Widget _cost(BuildContext context) {
    final textStyles = RiveTheme.of(context).textStyles;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
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
        padding: const EdgeInsets.only(top: 30),
        // child: FlatButton(child: Text('stff'), onPressed: () {}),
        child: Container(
          width: 181,
          child: FlatIconButton(
            mainAxisAlignment: MainAxisAlignment.center,
            label:
                (sub.processing) ? 'Processing Payment' : 'Create Team & Pay',
            color: (sub.processing) ? colors.buttonLight : colors.buttonDark,
            textColor: Colors.white,
            onTap: () {
              if (!sub.processing) {
                sub.submit(context, RiveContext.of(context).api);
              }
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
      height: 544,
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
