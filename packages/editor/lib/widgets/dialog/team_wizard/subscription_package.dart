import 'package:flutter/widgets.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/teams.dart';

/// Billing policy URL
const billingPolicyUrl =
    'https://docs.2dimensions.com/rive-help-center/get-started/fair-billing-policy';

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

  void submit(BuildContext context, RiveApi api) async {
    await _RiveTeamApi(api).createTeam(name);
    Navigator.of(context, rootNavigator: true).pop(null);
  }
}

class _RiveTeamApi extends RiveTeamsApi<RiveTeam> {
  _RiveTeamApi(RiveApi api) : super(api);
}
