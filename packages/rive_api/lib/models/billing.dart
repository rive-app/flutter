/// The subscription frequency options
enum BillingFrequency { yearly, monthly }

/// The subscription team option
enum TeamsOption { basic, premium }

class RiveTeamBilling {
  TeamsOption plan;

  BillingFrequency frequency;

  RiveTeamBilling({this.plan, this.frequency});

  factory RiveTeamBilling.fromData(Map<String, dynamic> data) {
    return RiveTeamBilling(
      plan: data.getPlan(),
      frequency: data.getFrequency(),
    );
  }

  @override
  String toString() {
    return '${plan.toString()} & ${frequency.toString()}';
  }
}

extension DeserializeHelperHelper on Map<String, dynamic> {
  TeamsOption getPlan() {
    dynamic value = this['plan'];
    switch (value) {
      case 'normal':
        return TeamsOption.basic;
      case 'premium':
        return TeamsOption.premium;
      default:
        return null;
    }
  }

  BillingFrequency getFrequency() {
    dynamic value = this['cycle'];
    switch (value) {
      case 'monthly':
        return BillingFrequency.monthly;
      case 'yearly':
        return BillingFrequency.yearly;
      default:
        return null;
    }
  }
}
