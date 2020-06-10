import 'package:rive_api/data_model.dart';

class CustomerInfo {
  const CustomerInfo._({
    this.brand,
    this.lastFour,
    this.expiryMonth,
    this.expiryYear,
    this.nextDay,
    this.nextMonth,
    this.nextYear,
  });

  final String brand;
  final String lastFour;
  final String expiryMonth;
  final String expiryYear;
  final String nextDay;
  final String nextMonth;
  final String nextYear;

  factory CustomerInfo.fromDM(CustomerInfoDM customer) => CustomerInfo._(
        brand: customer?.brand,
        lastFour: customer?.lastFour,
        expiryMonth: customer?.expiryMonth,
        expiryYear: customer?.expiryYear,
        nextDay: customer?.nextDay,
        nextMonth: customer?.nextMonth,
        nextYear: customer?.nextYear,
      );

  // Differentiate in FutureBuilder/Streams between
  // null values and empty values.
  bool get isEmpty => brand == null;

  String get cardDescription =>
      isEmpty ? 'n/a' : '$brand $lastFour. Expires $expiryMonth/$expiryYear';

  String get nextDue => isEmpty ? 'n/a' : '$nextMonth $nextDay, $nextYear';
}
