import 'package:rive_api/data_model.dart';

class BillingDetails {
  const BillingDetails({
    this.businessName,
    this.taxId,
    this.businessAddress,
  });

  final String businessName;
  final String taxId;
  final String businessAddress;

  factory BillingDetails.fromDM(BillingDetailsDM billingDetails) =>
      BillingDetails(
        businessName: billingDetails.businessName ?? '',
        taxId: billingDetails.taxId ?? '',
        businessAddress: billingDetails.businessAddress ?? '',
      );

  @override
  String toString() =>
      'Billing Details:($businessName, $taxId, $businessAddress)';
}
