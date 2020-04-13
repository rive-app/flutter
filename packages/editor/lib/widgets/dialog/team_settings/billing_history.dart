import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/team_settings/panel_section.dart';
import 'package:rive_editor/widgets/dialog/team_settings/labeled_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class BillingHistory extends StatelessWidget {
  final RiveTeam team;
  final RiveApi api;
  final billingHistory = BillingHistoryPackage();

  BillingHistory(this.team, this.api, {Key key}) : super(key: key);

  Widget _receiptColumn(BuildContext context, String header, List<String> rows,
      {CrossAxisAlignment columnAlignemnt = CrossAxisAlignment.start}) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;

    final headerStyle =
        styles.notificationHeader.copyWith(fontSize: 13, height: 1.6);
    final successStyle =
        styles.notificationHeaderSelected.copyWith(fontSize: 13, height: 1.6);
    final failedStyle =
        styles.hierarchyTabActive.copyWith(fontSize: 13, height: 1.6);

    return Expanded(
        child: Column(crossAxisAlignment: columnAlignemnt, children: [
      Text(header, style: headerStyle),
      for (int i = 0; i < rows.length; i++)
        Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(rows[i],
                style:
                    billingHistory.statuses[i] ? successStyle : failedStyle)),
    ]));
  }

  Widget _billingHistory(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _receiptColumn(context, 'Date', billingHistory.dates),
      _receiptColumn(context, 'Amount', billingHistory.amounts),
      _receiptColumn(
          context,
          'Status',
          billingHistory.statuses
              .map<String>((e) => e ? 'Success' : 'Failed')
              .toList(growable: false)),
      _receiptColumn(context, 'Description', billingHistory.descriptions),
      _receiptColumn(context, 'Receipts', billingHistory.receipts,
          columnAlignemnt: CrossAxisAlignment.end),
    ]);
  }

  Widget _textFieldRow(List<Widget> children) {
    if (children.isEmpty) {
      return const SizedBox();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: children.first),
        for (final child in children.sublist(1)) ...[
          const SizedBox(width: 30),
          Expanded(child: child)
        ]
      ],
    );
  }

  Widget _receiptDetails() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _textFieldRow([
            LabeledTextField(
              label: 'Business Name',
              hint: 'Company name for receipts',
              onChanged: (value) => billingHistory.businessName = value,
              initialValue: billingHistory.businessName,
            ),
            LabeledTextField(
              label: 'VAT/GST ID',
              hint: 'Optional',
              onChanged: (value) => billingHistory.vat = value,
              initialValue: billingHistory.vat,
            )
          ]),
          const SizedBox(height: 30),
          _textFieldRow([
            LabeledTextField(
              label: 'Business Name',
              hint: 'Add your company address of record',
              onChanged: (value) => billingHistory.businessName = value,
              initialValue: billingHistory.businessName,
            ),
          ])
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    final colors = theme.colors;
    return ListView(
        padding: const EdgeInsets.all(30),
        physics: const ClampingScrollPhysics(),
        children: [
          SettingsPanelSection(
              label: 'Receipt Options', contents: (ctx) => _receiptDetails()),
          const SizedBox(height: 30),
          Separator(color: colors.fileLineGrey),
          // Vertical padding.
          const SizedBox(height: 30),
          Text(
            'History',
            style: styles.fileGreyTextLarge,
          ),
          const SizedBox(height: 30),
          _billingHistory(context)
        ]);
  }
}

class BillingHistoryPackage {
  // TODO: connect with backend.
  List<String> dates = [
    'January 1, 2020',
    'December 5, 2019',
    'December 3, 2019',
    'November 3, 2019',
  ];
  List<String> amounts = ['\$168', '\$168', '\$168', '\$168'];
  List<bool> statuses = [true, true, false, true];
  List<String> descriptions = [
    'Pro (Monthly)',
    'Pro (Monthly)',
    'Pro (Monthly)',
    'Pro (Monthly)',
  ];
  List<String> receipts = ['PDF', 'PDF', '', 'PDF'];

  String businessName;
  String vat;
  String address;
}
