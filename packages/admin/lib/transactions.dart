import 'package:admin/manager.dart';
import 'package:flutter/material.dart';
import 'package:admin/tables.dart';
import 'package:flutter/services.dart';

const reservedUnitCodes = {'STRIPE_CHARGE'};

class Transactions extends StatelessWidget {
  final int ownerId;

  const Transactions({Key key, this.ownerId = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: AdminManager.instance.listTransactions(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            var table = DataTableView(
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
            if (ownerId == 0) {
              return table;
            } else {
              return Column(
                children: [
                  Expanded(child: table),
                  Expanded(child: TransactionForm(ownerId: ownerId))
                ],
              );
            }
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}

// Create a Form widget.
class TransactionForm extends StatefulWidget {
  final int ownerId;

  const TransactionForm({Key key, this.ownerId}) : super(key: key);
  @override
  TransactionFormState createState() {
    return TransactionFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class TransactionFormState extends State<TransactionForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<TransactionFormState>.
  final _formKey = GlobalKey<FormState>();
  bool enabled = true;

  final unitCodeController = TextEditingController();
  final unitCostController = TextEditingController();
  final unitCountController = TextEditingController();
  final headlineController = TextEditingController();
  final serviceTimeController = TextEditingController();
  final detailController = TextEditingController();

  void setEnable(bool _enabled) {
    setState(() {
      enabled = _enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            decoration: const InputDecoration(
                labelText: 'Confirm team id to add the transaction.'),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              if (widget.ownerId.toString() != value) {
                return 'must be equal to the selected team';
              }
              return null;
            },
          ),
          TextFormField(
            controller: unitCodeController,
            decoration:
                const InputDecoration(labelText: 'Unit code e.g. CUSTOM_TXN'),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              if (reservedUnitCodes.contains(value)) {
                return '$reservedUnitCodes are reserved codes';
              }
              return null;
            },
          ),
          TextFormField(
            controller: unitCostController,
            decoration:
                const InputDecoration(labelText: 'Unit Cost (in cents).'),
            inputFormatters: <TextInputFormatter>[
              WhitelistingTextInputFormatter(RegExp(r'^[-+]?\d*$'))
            ],
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
          ),
          TextFormField(
            controller: unitCountController,
            decoration: const InputDecoration(labelText: 'Unit Count e.g 1.'),
            inputFormatters: <TextInputFormatter>[
              WhitelistingTextInputFormatter.digitsOnly
            ],
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
          ),
          TextFormField(
            controller: headlineController,
            decoration:
                const InputDecoration(labelText: "headline e.g 'plan_renewal'"),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
          ),
          TextFormField(
            controller: serviceTimeController,
            decoration: const InputDecoration(
                labelText: "relevant service time e.g "
                    "'June 17, 2020 - June 17, 2021'"),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
          ),
          TextFormField(
            controller: detailController,
            decoration: const InputDecoration(
                labelText: "detail e.g 'Added Adam Pro Rata 22/31 Days'"),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              onPressed: enabled
                  ? () {
                      setEnable(false);
                      // Validate returns true if the form is valid, or false
                      // otherwise.
                      if (_formKey.currentState.validate()) {
                        // If the form is valid, display a Snackbar.
                        Scaffold.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')));

                        AdminManager.instance.createTransaction(
                          ownerId: widget.ownerId,
                          unitCode: unitCodeController.text,
                          unitCount: int.parse(unitCountController.text),
                          unitCost: int.parse(unitCostController.text),
                          headline: headlineController.text,
                          serviceTime: serviceTimeController.text,
                          detail: detailController.text,
                        );
                      }
                      setEnable(true);
                    }
                  : null,
              child: const Text('Charge Now!'),
            ),
          ),
        ],
      ),
    );
  }
}
