import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/common/rive_text_field.dart';
import 'package:rive_editor/widgets/dialog/shared/formatter.dart';
import 'package:rive_editor/widgets/dialog/shared/subscription_package.dart';

Widget cvcField(BuildContext context, SubscriptionPackage sub) {
  return RiveTextField(
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
  );
}

Widget postcodeField(BuildContext context, SubscriptionPackage sub) {
  return RiveTextField(
    onChanged: (zip) => sub.zip = zip,
    enabled: !sub.processing,
    initialValue: sub.zip,
    errorAlignment: MainAxisAlignment.start,
    formatters: <TextInputFormatter>[
      // Field lengths : the longest postal code currently
      // in use in the world is 10 digits long.
      LengthLimitingTextInputFormatter(10),
    ],
    hintText: '90210',
    errorText: sub.zipError,
  );
}

Widget creditCardField(BuildContext context, SubscriptionPackage sub) {
  return RiveTextField(
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
  );
}

Widget expirationField(BuildContext context, SubscriptionPackage sub) {
  return RiveTextField(
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
  );
}
