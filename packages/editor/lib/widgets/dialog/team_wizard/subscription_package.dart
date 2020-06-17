import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team_invite_status.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/stripe.dart';
import 'package:rive_api/teams.dart';
import 'package:utilities/utilities.dart';

/// Billing policy URL
const billingPolicyUrl = 'https://help.rive.app/pricing/fair-billing-policy';

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
  // Bit nasty, but riveapi is context bound :/
  RiveApi api;

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

  bool _isCanceled;
  bool get isCanceled => _isCanceled;

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

  /// Form Processing
  bool _processing = false;
  bool get processing => _processing;
  set processing(bool value) {
    if (_processing == value) {
      return;
    }
    _processing = value;
    notifyListeners();
  }

  String get expMonth => expiration.split('/').first;
  String get expYear => '20${expiration.split('/').last}';
}

/// Data class for managing subscription data in the Team Settings 'Plan' modal.
class PlanSubscriptionPackage extends SubscriptionPackage {
  PlanSubscriptionPackage(this.team);

  /// The team data.
  final Team team;

  int get currentCost => calculatedCost;

  int _teamSize;
  @override
  int get teamSize => _teamSize;

  @override
  set option(TeamsOption value) {
    if (_option == value) return;
    _option = value;
    notifyListeners();
  }

  bool get isChanging => costDifference != 0;
  int get costDifference => calculatedCost - currentCost;

  String _cardDescription;
  String get cardDescription => _cardDescription;

  DateTime _nextDue;
  DateTime get nextDue => _nextDue;
  set nextDue(DateTime value) {
    if (value != _nextDue) {
      _nextDue = value;
      notifyListeners();
    }
  }

  bool get isActive => _nextDue.isAfter(DateTime.now());

  String _nextDueDescription;
  String get nextDueDescription => _nextDueDescription;

  void setDescriptions(RiveTeamBilling billing) {
    var newDescription = billing.brand == null
        ? 'n/a'
        : '${billing.brand} ${billing.lastFour}. '
            'Expires ${billing.expiryMonth}/${billing.expiryYear}';
    if (_cardDescription != newDescription) {
      _cardDescription = newDescription;
      notifyListeners();
    }

    var newDue = billing.brand == null ? 'n/a' : '${_nextDue.description}';
    if (_nextDueDescription != newDue) {
      _nextDueDescription = newDue;
      notifyListeners();
    }
  }

  static Future<PlanSubscriptionPackage> fetchData(
    RiveApi api,
    Team team,
  ) async {
    var billing = await RiveTeamsApi(api).getBillingInfo(team.ownerId);

    // Need to compute team size.
    var collaborators = Plumber().peek<List<TeamMember>>(team.hashCode);
    if (collaborators != null) {
      // If, for some reason, team was not fully loaded, force a load here.
      await TeamManager().loadTeamMembers(team);
      collaborators = Plumber().peek<List<TeamMember>>(team.hashCode);
    }

    var subscription = PlanSubscriptionPackage(team)
      ..api = api
      ..option = billing.plan
      ..billing = billing.frequency
      ..nextDue = billing.nextDue
      .._isCanceled = billing.isCanceled
      .._teamSize = collaborators
          .where((element) => element.status == TeamInviteStatus.accepted)
          .length
      ..setDescriptions(billing);

    return subscription;
  }

  Future<bool> _updatePlan() async {
    var res = await RiveTeamsApi(api).updatePlan(team.ownerId, option, billing);
    if (res) {
      notifyListeners();
    }
    return res;
  }

  Future<bool> renewPlan(bool renew) async {
    if (processing) {
      return false;
    }
    processing = true;

    var res = await RiveTeamsApi(api).renewPlan(team.ownerId, renew);

    processing = false;
    return res;
  }

  // Once we've submitted the information to the backend, clean up
  // the form fields by resetting the values of this object.
  void _cardCleanup() {
    _cardNumber = null;
    expiration = null;
    ccv = null;
    zip = null;
  }

  Future<bool> submitChanges(bool hasNewCC) async {
    if (processing) {
      return false;
    }
    processing = true;

    if (hasNewCC) {
      if (!await _updateCard()) {
        processing = false;
        return false;
      }
    }

    if (isChanging) {
      if (!await _updatePlan()) {
        processing = false;
        return false;
      }
    }
    // All good.
    processing = false;
    return true;
  }

  Future<bool> _updateCard() async {
    // Track that everything went fine.
    bool success = false;
    try {
      var publicKey = await StripeApi(api).getStripePublicKey();
      var tokenResponse =
          await createToken(publicKey, cardNumber, expMonth, expYear, ccv, zip);
      _cardCleanup();
      success = await TeamManager().saveToken(team, tokenResponse.token);

      // Get the new changes.
      var billing = await RiveTeamsApi(api).getBillingInfo(team.ownerId);
      setDescriptions(billing);
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
    }

    return success;
  }
}

/// Data class for tracking data in the team subscription widget
class TeamSubscriptionPackage extends SubscriptionPackage {
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
