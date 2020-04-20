import 'dart:convert';

import 'package:http/http.dart';

const baseUrl = 'https://api.stripe.com/';

// curl https://api.stripe.com/v1/tokens \
//   -u $STRIPE_PK: \
//   -d "card[number]"=$CARD_NUMBER \
//   -d "card[exp_month]"=$CARD_EXP_MONTH \
//   -d "card[exp_year]"=$CARD_EXP_YEAR \
//   -d "card[cvc]"=$CARD_CVC
Future<TokenResponse> createToken(
  String publicKey,
  String cardNumber,
  String expMonth,
  String expYear,
  String ccv,
  String zip,
) async {
  final client = Client();
  Map<String, String> body = {
    "card[number]": cardNumber,
    "card[exp_month]": expMonth,
    "card[exp_year]": expYear,
    "card[cvc]": ccv,
    "card[address_zip]": zip
  };
  Map<String, String> headers = {
    "Authorization": "Bearer $publicKey",
  };
  var response =
      await client.post('$baseUrl/v1/tokens', headers: headers, body: body);

  if (response.statusCode == 200) {
    var responseBody = json.decode(response.body) as Map<String, dynamic>;
    return TokenResponse(responseBody);
  } else {
    throw StripeAPIError(response);
  }
}

enum StripeErrorTypes { cardNumber, cardCCV, cardExpiration, general, unknown }

class StripeAPIError implements Exception {
  final Response _response;
  Response get response => _response;
  Map<String, dynamic> _responseJson;

  StripeAPIError(this._response);

  Map<String, dynamic> get responseJson {
    // dart hints got me here. im not even sure hwat im looking at.
    return _responseJson ??= json.decode(response.body) as Map<String, dynamic>;
  }

  String get error => responseJson['error']['message'] as String;

  StripeErrorTypes get type {
    if (responseJson['error']['type'] as String != 'card_error') {
      return StripeErrorTypes.general;
    } else {
      switch (responseJson['error']['param'] as String) {
        case 'number':
          return StripeErrorTypes.cardNumber;
        case 'cvc':
          return StripeErrorTypes.cardCCV;
        case 'exp_year':
        case 'exp_month':
          return StripeErrorTypes.cardExpiration;
      }
    }
    return StripeErrorTypes.unknown;
  }

  @override
  String toString() {
    return 'StripeApiError: ${response.statusCode}: $error';
  }
}

class TokenResponse {
  final Map<String, dynamic> payload;

  TokenResponse(this.payload);

  String get token => payload['id'] as String;
}

Future<void> main(List<String> args) async {
  var response = await createToken('pk_test_fOkU5ydE1avtd7GA6FcbKLev',
      '4242424242424242', '04', '2021', '314', 'asdfsdfsdfds');
  print(response);
}
