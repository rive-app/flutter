import 'package:utilities/deserialize.dart';

class HistoryChargeDM {
  const HistoryChargeDM._({
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

  factory HistoryChargeDM.fromData(Map<String, Object> data) =>
      HistoryChargeDM._(
        created: DateTime.parse(data.getString('created')),
        amount: data.getInt('amount'),
        successful: data.getInt('successful') == 1,
        receiptUrl: data.getString('receipt'),
        // TODO: description tbd.
      );

  @override
  String toString() =>
      'Charge DM:($amount, $created, $receiptUrl)';
}
