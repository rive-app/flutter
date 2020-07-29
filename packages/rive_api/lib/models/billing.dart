import 'package:rive_api/model.dart';
import 'package:utilities/deserialize.dart';

/// The subscription frequency options
enum BillingFrequency { yearly, monthly }

/// The subscription team option
enum TeamsOption { basic, premium }

extension TeamsOptionName on TeamsOption {
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

/// Represents the Billing information for a team:

class RiveTeamBilling {
  const RiveTeamBilling._(
      {this.plan,
      this.frequency,
      this.isCanceled,
      this.brand,
      this.lastFour,
      this.expiryMonth,
      this.expiryYear,
      this.nextDue,
      this.balance,
      this.nextBill,
      this.status});

  /// - plan type: {studio | org}
  final TeamsOption plan;

  /// - billing cycle: {monthly | yearly}
  final BillingFrequency frequency;

  /// - plan has been canceled:
  ///   it will not renew at the end of the next billing cycle
  final bool isCanceled;

  /// - Card brand
  final String brand;

  /// - Card last 4 digits
  final String lastFour;

  /// - Card expiry date
  final String expiryMonth;
  final String expiryYear;

  /// - Plan next payment date
  final DateTime nextDue;

  /// - Current balance on the account, can be negative to indicate credit
  final int balance;

  /// - How much the next bill is going to be, this includes the current balance
  /// - if its negative, there won't be a next bill
  final int nextBill;

  /// - up to date team billing status.
  final TeamStatus status;

  factory RiveTeamBilling.fromData(Map<String, Object> data) {
    return RiveTeamBilling._(
        plan: data.getPlan(),
        frequency: data.getFrequency(),
        isCanceled: data.getBool('isCanceled'),
        brand: data.getString('brand'),
        lastFour: data.getString('last4'),
        expiryMonth: data.getString('expMonth'),
        expiryYear: data.getString('expYear'),
        balance: data.getInt('balance'),
        nextBill: data.getInt('nextBill'),
        nextDue: DateTime.parse(data.getString('nextDue')),
        status: TeamStatusExtension.fromString(data.getString('status')));
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
