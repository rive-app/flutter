import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_api/stripe.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:utilities/utilities.dart';

/// Billing policy URL
const billingPolicyUrl =
    'https://docs.2dimensions.com/rive-help-center/get-started/fair-billing-policy';

const premiumYearlyCost = 45;
const basicYearlyCost = 14;
const premiumMonthlyCost = 68;
const basicMonthlyCost = 21;

final Map<BillingFrequency, Map<TeamsOption, int>> costLookup = {
  BillingFrequency.yearly: {
    TeamsOption.premium: premiumYearlyCost,
    TeamsOption.basic: basicYearlyCost,
  },
  BillingFrequency.monthly: {
    TeamsOption.premium: premiumMonthlyCost,
    TeamsOption.basic: basicMonthlyCost,
  }
};

/// The active wizard panel
enum WizardPanel { one, two }

abstract class SubscriptionPackage with ChangeNotifier {
  /// Team subscription freuqency
  BillingFrequency _billing = BillingFrequency.yearly;
  BillingFrequency get billing => _billing;
  set billing(BillingFrequency value) {
    if (_billing == value) return;
    _billing = value;
    notifyListeners();
  }

  /// The teams option
  TeamsOption _option;
  TeamsOption get option => _option;
  set option(TeamsOption value);

  int get teamSize;

  int get cost => costLookup[_billing][_option];

  /// Returns the initial billing cost for the selected options
  int get calculatedCost {
    return teamSize * cost * (_billing == BillingFrequency.yearly ? 12 : 1);
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

  /// Validate the team options
  bool get isOptionValid => _option != null;

  /// Validate the credit card
  bool get isCardNrValid {
    if (_cardNumber == null) {
      _cardValidationError = 'Missing card number';
      return false;
    }

    if (!RegExp(r'^[0-9]{4} [0-9]{4} [0-9]{4} [0-9]{4}$')
        .hasMatch(_cardNumber)) {
      _cardValidationError = 'Card number format mismatch';
      return false;
    }
    _cardValidationError = null;
    return true;
  }

  bool get isCcvValid {
    if (_ccv == null) {
      _ccvError = 'Missing';
      return false;
    }

    if (_ccv.length < 3) {
      _ccvError = 'Incomplete';
      return false;
    }
    _ccvError = null;
    return true;
  }

  bool get isZipValid {
    if (_zip == null) {
      _zipError = 'Missing';
      return false;
    }

    if (_zip.length < 5) {
      _zipError = 'Incomplete';
      return false;
    }
    _zipError = null;
    return true;
  }

  bool get isExpirationValid {
    if (_expiration == null) {
      _expirationError = 'Missing';
      return false;
    }

    if (_expiration.length < 5) {
      _expirationError = 'Incomplete';
      return false;
    }
    _expirationError = null;
    return true;
  }

  // User friendly error messages
  String _cardValidationError;
  String get cardValidationError => _cardValidationError;

  String _ccvError;
  String get ccvError => _ccvError;

  String _expirationError;
  String get expirationError => _expirationError;

  String _zipError;
  String get zipError => _zipError;
}

/// Data class for managing subscription data in the Team Settings 'Plan' modal.
class PlanSubscriptionPackage extends SubscriptionPackage {
  // TODO: current plan expiration date.
  int _currentCost;
  int get currentCost => _currentCost;

  int _teamSize;
  @override
  int get teamSize => _teamSize;

  static Future<PlanSubscriptionPackage> fetchData(
      RiveApi api, RiveTeam team) async {
    var response = await RiveTeamsApi(api).getBillingInfo(team.ownerId);
    var subscription = PlanSubscriptionPackage()
      ..option = response.plan
      ..billing = response.frequency
      .._teamSize = team.teamMembers.length;
    subscription._currentCost = subscription.calculatedCost;

    return subscription;
  }

  Future<bool> updatePlan(RiveApi api, int teamId) async {
    var res = await RiveTeamsApi(api).updatePlan(teamId, option, billing);
    if (res) {
      _currentCost = calculatedCost;
      notifyListeners();
    }
    return res;
  }

  @override
  set option(TeamsOption value) {
    if (_option == value) return;
    _option = value;
    notifyListeners();
  }
}

/// Data class for tracking data in the team subscription widget
class TeamSubscriptionPackage extends SubscriptionPackage {
  // Bit nasty, but riveapi is context bound :/
  RiveApi api;

  /// Team name
  String _name;
  String get name => _name;
  set name(String value) {
    _name = value;
    _nameCheckPassed = null;
    notifyListeners();
  }

  Timer _nameCheckDebounce;
  bool _nameCheckPassed;
  bool get nameCheckPassed => _nameCheckPassed;
  set nameCheckPassed(bool value) {
    if (_nameCheckPassed != value) {
      _nameCheckPassed = value;
      // trigger reset of name error
      isNameValid;
      notifyListeners();
    }
  }

  /// Form Processing
  bool _processing = false;
  bool get processing => _processing;
  set processing(bool value) {
    _processing = value;
    notifyListeners();
  }

  @override
  set option(TeamsOption value) {
    if (isNameValid) {
      _option = value;
    } else {
      // assign name to be '' if its been set yet
      // this teases an error out
      name ??= '';
    }
    notifyListeners();
  }

  // When creating a team, team size is only the creator.
  @override
  int get teamSize => 1;

  // User friendly Name validation error messages
  String _nameValidationError;
  String get nameValidationError => _nameValidationError;

  /// Validates the team name
  bool get isNameValid {
    /// Minimum length for a valid team name.
    const _minTeamNameLength = 4;

    /// Regex for valid team names
    final _legalNameMatch = RegExp(r'^[A-Za-z0-9]+$');

    if (name == null) {
      // never entered a name... lets ignore it
      return false;
    }

    if (name == '') {
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
    if (nameCheckPassed == null) {
      checkName();
      _nameValidationError = 'Checking name...';
      return false;
    }
    if (nameCheckPassed == false) {
      _nameValidationError = 'Name reserved, please choose another';
      return false;
    }
    _nameValidationError = null;
    return true;
  }

  /// Step 1 is valid; safe to proceed to step 2
  bool get isStep1Valid => isNameValid && isOptionValid;

  bool get isCardInputValid {
    // Matt, im sure there's a better way to do this
    // we want to check all of these, as they set errors
    // as a byproduct...
    // I guess its a bit of a shite pattern, shoulg probably
    // have a validate function thats separate...
    isCardNrValid;
    isZipValid;
    isExpirationValid;
    isCcvValid;
    nameCheckPassed;
    return isCardNrValid &&
        isZipValid &&
        isExpirationValid &&
        isCcvValid &&
        nameCheckPassed;
  }

  /// Step 2 is valid; safe to attempt team creation
  bool get isStep2Valid => isNameValid && isOptionValid && isCardInputValid;

  String get expMonth => expiration.split('/').first;
  String get expYear => '20${expiration.split('/').last}';

  Future checkName() async {
    if (_nameCheckDebounce?.isActive ?? false) _nameCheckDebounce.cancel();
    _nameCheckDebounce = Timer(const Duration(milliseconds: 233), _checkName);
  }

  Future _checkName() async {
    final _nameCache = name;
    final _checkPassed = await RiveTeamsApi(api).checkName(teamName: name);
    // its async, lest make sure we're still looking at the result
    // for the quesetion we asked.
    if (_nameCache == name) nameCheckPassed = _checkPassed;
  }

  Future submit(BuildContext context, RiveApi api) async {
    if (isStep2Valid) {
      processing = true;

      try {
        var publicKey = await StripeApi(api).getStripePublicKey();
        var tokenResponse = await createToken(
            publicKey, cardNumber, expMonth, expYear, ccv, zip);
        var newTeam = await RiveTeamsApi(api).createTeam(
            teamName: name,
            plan: _option.name,
            frequency: _billing.name,
            stripeToken: tokenResponse.token);
        // TODO: try to just push the new team right into
        // to avoid reloading all other teams
        // TODO: select team on create
        TeamManager().loadTeams();
        // todo kill this once we kill old system:
        // await RiveContext.of(context).reloadTeams();
        // await RiveContext.of(context).selectRiveOwner(newTeam.ownerId);
        Navigator.of(context, rootNavigator: true).pop();
      } on StripeAPIError catch (error) {
        switch (error.type) {
          case StripeErrorTypes.cardNumber:
            _cardValidationError = error.error;
            break;
          case StripeErrorTypes.cardCCV:
            _ccvError = error.error;
            break;
          case StripeErrorTypes.cardExpiration:
            _expirationError = error.error;
            break;
          default:
            // todo.. fine
            _cardValidationError = error.error;
        }
      } on ApiException catch (exception) {
        // card validation error is just the most convenient
        // place to display this
        _cardValidationError = exception.error.message;
      } finally {
        processing = false;
      }
    } else {
      notifyListeners();
    }
  }
}
