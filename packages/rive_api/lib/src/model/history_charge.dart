import 'package:rive_api/data_model.dart';

class HistoryCharge {
  const HistoryCharge._({
    this.created,
    this.amount,
    this.successful,
    this.description,
    this.receiptUrl,
  });

  final DateTime created;
  final int amount;
  final bool successful;
  final String description;
  final String receiptUrl;

  static List<HistoryCharge> fromDMList(List<HistoryChargeDM> chargeList) =>
      chargeList.map((e) => HistoryCharge._fromDM(e)).toList(growable: false);

  factory HistoryCharge._fromDM(HistoryChargeDM charge) => HistoryCharge._(
        created: charge?.created,
        amount: charge?.amount,
        successful: charge?.successful,
        receiptUrl: charge?.receiptUrl,
        description: charge?.description,
      );

  @override
  String toString() => 'Charge:($amount, $created, $receiptUrl)';
}
