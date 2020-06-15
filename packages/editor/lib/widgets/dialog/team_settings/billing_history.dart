import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/team_settings/panel_section.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

enum NetworkResponse { ok, error }

class BillingHistory extends StatefulWidget {
  const BillingHistory(this.team, this.api, {Key key}) : super(key: key);

  final Team team;
  final RiveApi api;

  @override
  _BillingHistoryState createState() => _BillingHistoryState();
}

class _BillingHistoryState extends State<BillingHistory> {
  // TODO: fetch history from the backend.
  final billingHistory = BillingHistoryPackage();

  BillingDetails _billingDetails;
  String _name, _tax, _address;
  bool _canUpdate = false;
  NetworkResponse _response;

  @override
  void initState() {
    TeamManager().getBillingDetails(widget.team).then((val) {
      // No need to setState() as getBillingDetails() will send a message
      // through the plumber and update the widget anyway.
      _billingDetails = val;
      _name = _billingDetails.businessName;
      _tax = _billingDetails.taxId;
      _address = _billingDetails.businessAddress;
    });
    super.initState();
  }

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

  Future<void> _updateReceiptDetails() async {
    setState(() {
      _canUpdate = false;
    });

    final uploadingDetails = BillingDetails(
      businessName: _name,
      taxId: _tax,
      businessAddress: _address,
    );
    bool success = await TeamManager().setBillingDetails(
      widget.team,
      uploadingDetails,
    );

    setState(() {
      if (success) {
        _billingDetails = uploadingDetails;
        _response = NetworkResponse.ok;
      } else {
        _response = NetworkResponse.error;
      }
    });

    Timer(
      const Duration(seconds: 2),
      () => setState(
        () {
          // Remove icon from the button.
          _response = null;
        },
      ),
    );

    _checkCanUpdate();
  }

  void _checkCanUpdate() {
    final allSame = _name == _billingDetails.businessName &&
        _tax == _billingDetails.taxId &&
        _address == _billingDetails.businessAddress;
    setState(() {
      _canUpdate = !allSame;
    });
  }

  Iterable<PackedIcon> get _responseIcon => _response == NetworkResponse.ok
      ? PackedIcon.popupCheck
      : PackedIcon.delete;

  Widget _receiptDetails(BillingDetails initialDetails) {
    final colors = RiveTheme.of(context).colors;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 3),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Business Name',
              hintText: 'Company name for receipts',
              onChanged: (value) {
                _name = value;
                _checkCanUpdate();
              },
              initialValue: initialDetails.businessName,
            ),
            LabeledTextField(
              label: 'VAT/GST ID',
              hintText: 'Optional',
              onChanged: (value) {
                _tax = value;
                _checkCanUpdate();
              },
              initialValue: initialDetails.taxId,
            )
          ],
        ),
        const SizedBox(height: 30),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Address',
              hintText: 'Add your company address of record',
              onChanged: (value) {
                _address = value;
                _checkCanUpdate();
              },
              initialValue: initialDetails.businessAddress,
            ),
          ],
        ),
        const SizedBox(height: 25),
        FlatIconButton(
          icon: _response != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TintedIcon(
                    icon: _responseIcon,
                    color: Colors.white,
                  ),
                )
              : null,
          label: 'Update',
          color: _canUpdate ? colors.commonDarkGrey : colors.commonLightGrey,
          textColor: Colors.white,
          onTap: _canUpdate ? _updateReceiptDetails : null,
          elevation: _canUpdate ? 8 : 0,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    final colors = theme.colors;

    return ValueStreamBuilder<BillingDetails>(
      stream: Plumber().getStream<BillingDetails>(widget.team.hashCode),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView(
            padding: const EdgeInsets.all(30),
            physics: const ClampingScrollPhysics(),
            children: [
              SettingsPanelSection(
                label: 'Receipt Options',
                contents: (ctx) => _receiptDetails(snapshot.data),
              ),
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
            ],
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                )
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
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
}
