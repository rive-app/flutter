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
    final receiptsList = receiptsData.map((Object receipt) {
      if (receipt is Map<String, Object>) {
        return HistoryChargeDM.fromData(receipt);
      } else {
        throw ArgumentError('Receipt type mismatch: ${receipt.runtimeType}');
      }
    }).toList(growable: false);

    final detailsData = data['receipt'] as Map<String, Object>;
    return BillingDetailsDM._(
      receipts: receiptsList,
      businessName: detailsData.getString('business_name'),
      taxId: detailsData.getString('tax_id'),
      businessAddress: detailsData.getString('business_address'),
    );
  }
}
