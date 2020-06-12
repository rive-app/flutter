import 'package:utilities/deserialize.dart';

class BillingDetailsDM {
  const BillingDetailsDM._({
    this.businessName,
    this.taxId,
    this.businessAddress,
  });

  final String businessName;
  final String taxId;
  final String businessAddress;

  factory BillingDetailsDM.fromData(Map<String, Object> data) =>
      BillingDetailsDM._(
        businessName: data.getString('bn'),
        taxId: data.getString('tid'),
        businessAddress: data.getString('ba'),
      );

  @override
  String toString() =>
      'Billing Details:($businessName, $taxId, $businessAddress)';
}
