import 'package:utilities/deserialize.dart';

class CustomerInfoDM {
  const CustomerInfoDM._({
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

  factory CustomerInfoDM.fromData(Map<String, Object> data) => CustomerInfoDM._(
        brand: data.getString('brand'),
        lastFour: data.getString('last4'),
        expiryMonth: data.getString('expMonth'),
        expiryYear: data.getString('expYear'),
        nextDay: data.getString('nextDay'),
        nextMonth: data.getString('nextMonth'),
        nextYear: data.getString('nextYear'),
      );
}
