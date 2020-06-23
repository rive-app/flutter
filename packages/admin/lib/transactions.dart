import 'package:admin/charges.dart';
import 'package:admin/manager.dart';
import 'package:flutter/material.dart';
import 'package:admin/tables.dart';

class Transactions extends StatelessWidget {
  final int ownerId;

  const Transactions({Key key, this.ownerId = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: AdminManager.instance.listTransactions(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return DataTableView(
                'Transactions',
                snapshot.data,
                const [
                  'ownerId',
                  'name',
                  'username',
                  'unitCode',
                  'unitCost',
                  'total',
                  'balance',
                  'headline',
                  'serviceTime',
                  'detail',
                  'created'
                ],
                {
                  'ownerId': (dynamic row) => () {
                        Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (pageContext) => Scaffold(
                                      appBar: AppBar(
                                        title: Text(
                                            'Transactions: ${row["name"]}'),
                                      ),
                                      body: Transactions(
                                          ownerId: row['ownerId'] as int),
                                    )));
                      }
                },
                filter: (dynamic row) =>
                    (ownerId == 0) || row['ownerId'] as int == ownerId);
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
