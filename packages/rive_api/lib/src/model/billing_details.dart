import 'package:rive_api/data_model.dart';
import 'package:rive_api/model.dart';

class BillingDetails {
  const BillingDetails({
    this.receipts,
    this.businessName,
    this.taxId,
    this.businessAddress,
  });

  // All the receipts
  final List<HistoryCharge> receipts;
  // Receipt Details
  final String businessName;
  final String taxId;
  final String businessAddress;

  factory BillingDetails.fromDM(BillingDetailsDM billingDetails) =>
      BillingDetails(
        receipts: HistoryCharge.fromDMList(billingDetails.receipts),
        businessName: billingDetails.businessName ?? '',
        taxId: billingDetails.taxId ?? '',
        businessAddress: billingDetails.businessAddress ?? '',
      );
}
