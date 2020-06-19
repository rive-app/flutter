import 'package:rive_api/src/data_model/history_charge.dart';
import 'package:utilities/deserialize.dart';

class BillingDetailsDM {
  const BillingDetailsDM._({
    this.receipts,
    this.businessName,
    this.taxId,
    this.businessAddress,
  });

  final List<HistoryChargeDM> receipts;
  // Receipt details
  final String businessName;
  final String taxId;
  final String businessAddress;

  factory BillingDetailsDM.fromData(Map<String, Object> data) {
    final receiptsData = data['output'] as List;
    print("This is the receiptsData I got: $receiptsData");
    final receiptsList = receiptsData.map((Object receipt) {
      if (receipt is Map<String, Object>) {
        return HistoryChargeDM.fromData(receipt);
      } else {
        throw ArgumentError('Receipt type mismatch: ${receipt.runtimeType}');
      }
    }).toList(growable: false);

    print("Got all my receipts: $receiptsList");

    final detailsData = data['receipt'] as Map<String, Object>;
    print("And these are details: $detailsData");
    return BillingDetailsDM._(
      receipts: receiptsList,
      businessName: detailsData.getString('business_name'),
      taxId: detailsData.getString('tax_id'),
      businessAddress: detailsData.getString('business_address'),
    );
  }
}
