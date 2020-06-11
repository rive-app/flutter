import 'package:utilities/deserialize.dart';

/// The subscription frequency options
enum BillingFrequency { yearly, monthly }

/// The subscription team option
enum TeamsOption { basic, premium }

extension PlanExtension on TeamsOption {
  String get name {
    switch (this) {
      case TeamsOption.premium:
        return 'premium';
      case TeamsOption.basic:
      default:
        return 'normal';
    }
  }
}

extension FrequencyExtension on BillingFrequency {
  String get name {
    switch (this) {
      case BillingFrequency.yearly:
        return 'yearly';
      case BillingFrequency.monthly:
      default:
        return 'monthly';
    }
  }

  static BillingFrequency fromName(String cycle) {
    switch (cycle) {
      case 'monthly':
        return BillingFrequency.monthly;
      case 'yearly':
        return BillingFrequency.yearly;
      default:
        throw ArgumentError('Invalid billing frequency: $cycle');
    }
  }
}

class RiveTeamBilling {
  const RiveTeamBilling._({
    this.plan,
    this.frequency,
    this.brand,
    this.lastFour,
    this.expiryMonth,
    this.expiryYear,
    this.nextDay,
    this.nextMonth,
    this.nextYear,
  });

  final TeamsOption plan;
  final BillingFrequency frequency;
  final String brand;
  final String lastFour;
  final String expiryMonth;
  final String expiryYear;
  final String nextDay;
  final String nextMonth;
  final String nextYear;

  factory RiveTeamBilling.fromData(Map<String, Object> data) {
    return RiveTeamBilling._(
      plan: data.getPlan(),
      frequency: data.getFrequency(),
      brand: data.getString('brand'),
      lastFour: data.getString('last4'),
      expiryMonth: data.getString('expMonth'),
      expiryYear: data.getString('expYear'),
      nextDay: data.getString('nextDay'),
      nextMonth: data.getString('nextMonth'),
      nextYear: data.getString('nextYear'),
    );
  }

  @override
  String toString() {
    return '${plan.toString()} & ${frequency.toString()}';
  }
}

extension DeserializeHelperHelper on Map<String, Object> {
  TeamsOption getPlan() {
    Object value = this['plan'];
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'normal':
          return TeamsOption.basic;
        case 'premium':
          return TeamsOption.premium;
        default:
          return null;
      }
    }
    return null;
  }

  BillingFrequency getFrequency() {
    Object value = this['cycle'];
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'monthly':
          return BillingFrequency.monthly;
        case 'yearly':
          return BillingFrequency.yearly;
        default:
          return null;
      }
    }
    return null;
  }
}
