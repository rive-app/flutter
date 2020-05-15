import 'dart:convert';
import 'dart:core';

import 'package:logging/logging.dart';

import 'package:rive_api/api.dart';

final Logger log = Logger('Rive API');

/// Api for accessing the signed in users folders and files.
class StripeApi {
  const StripeApi(this.api);
  final RiveApi api;

  /// POST /api/teams
  Future<String> getStripePublicKey() async {
    // If we start needing more here, it may be worth making a response model.

    var response = await api.get(api.host + '/api/config/stripe');
    Map<String, dynamic> data = json.decode(response.body);

    return data['data']['stripe_pk'] as String;
  }
}
