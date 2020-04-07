import 'package:flutter/widgets.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// Billing policy URL
const billingPolicyUrl =
    'https://docs.2dimensions.com/rive-help-center/get-started/fair-billing-policy';

const premiumMonthlyCost = 45;
const basicMonthlyCost = 14;

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

  int get monthlyCost =>
      _option == TeamsOption.premium ? premiumMonthlyCost : basicMonthlyCost;

  /// Returns the initial billing cost for the selected options
  int get calculatedCost {
    return teamSize *
        monthlyCost *
        (_billing == BillingFrequency.yearly ? 12 : 1);
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
      return false;
    }

    if (!RegExp(r'^[0-9]{16}$').hasMatch(_cardNumber)) {
      return false;
    }
    return true;
  }
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
  /// Team name
  String _name;
  String get name => _name;
  set name(String value) {
    _name = value;
    notifyListeners();
  }

  @override
  set option(TeamsOption value) {
    if (isNameValid) {
      _option = value;
    }
    notifyListeners();
  }

  // When creating a team, team size is only the creator.
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

  /// Step 1 is valid; safe to proceed to step 2
  bool get isStep1Valid => isNameValid && isOptionValid;

  /// Step 2 is valid; safe to attempt team creation
  bool get isStep2Valid => isNameValid && isOptionValid && isCardNrValid;

  Future submit(BuildContext context, RiveApi api) async {
    await RiveTeamsApi(api).createTeam(
        teamName: name, plan: _option.name, frequency: _billing.name);
    await RiveContext.of(context).reloadTeams();
    Navigator.of(context, rootNavigator: true).pop(null);
  }
}
