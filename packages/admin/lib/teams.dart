import 'package:admin/manager.dart';
import 'package:flutter/material.dart';
import 'package:admin/tables.dart';

class Teams extends StatelessWidget {
  final int ownerId;

  const Teams({Key key, this.ownerId = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: AdminManager.instance.listTeams(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return DataTableView(
                'Teams',
                snapshot.data,
                const [
                  'ownerId',
                  'name',
                  'username',
                  'renewSubscription',
                  'nextBillingDate',
                  'currentPlanType',
                  'currentBillingCycle',
                  'nextPlanType',
                  'nextBillingCycle',
                  'totalPaid',
                  'memberCount',
                  'balance',
                  'status',
                ],
                {
                  'ownerId': (dynamic row) => () {
                        Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (pageContext) => Scaffold(
                                      appBar: AppBar(
                                        title: Text('Teams: ${row["name"]}'),
                                      ),
                                      body:
                                          Teams(ownerId: row["ownerId"] as int),
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
