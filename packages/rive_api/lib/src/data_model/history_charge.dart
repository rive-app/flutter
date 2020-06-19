import 'package:utilities/deserialize.dart';

enum PlanCode { studio, studioYearly, org, orgYearly, unknown }

extension PlanCodeExtension on PlanCode {
  String get planName => <PlanCode, String>{
        PlanCode.studio: 'Studio (Monthly)',
        PlanCode.studioYearly: 'Studio (Yearly)',
        PlanCode.org: 'Org (Monthly)',
        PlanCode.orgYearly: 'Org (Yearly)',
        PlanCode.unknown: 'n/a',
      }[this];

  static PlanCode fromName(String name) => <String, PlanCode>{
        'STUDIO': PlanCode.studio,
        'STUDIO_YEARLY': PlanCode.studioYearly,
        'ORG': PlanCode.org,
        'ORG_YEARLY': PlanCode.orgYearly,
      }[name];
}

class HistoryChargeDM {
  const HistoryChargeDM._({
    this.created,
    this.amount,
    this.successful,
    this.planCodes,
    this.receiptUrl,
  });

  final DateTime created;
  final int amount;
  final bool successful;
  final List<PlanCode> planCodes;
  final String receiptUrl;

  factory HistoryChargeDM.fromData(Map<String, Object> data) =>
      HistoryChargeDM._(
          created: DateTime.parse(data.getString('created')),
          amount: data.getInt('amount'),
          successful: data.getInt('successful') == 1,
          receiptUrl: data.getString('receipt'),
          planCodes: data
              .getList<String>('relatedLineItemCodes')
              .map((e) => PlanCodeExtension.fromName(e) ?? PlanCode.unknown)
              .toList(growable: false));

  @override
  String toString() => 'Charge DM:($amount, $created, $receiptUrl, $planCodes)';
}
