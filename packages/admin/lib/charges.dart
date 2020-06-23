import 'package:admin/manager.dart';
import 'package:flutter/material.dart';
import 'package:admin/tables.dart';

class Charges extends StatelessWidget {
  final int ownerId;

  const Charges({Key key, this.ownerId = 0}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: AdminManager.instance.listCharges(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            var table = DataTableView(
                'Charges',
                snapshot.data,
                const [
                  'ownerId',
                  'name',
                  'username',
                  'chargeId',
                  'created',
                  'successful',
                  'errorMessage',
                  'paymentSource',
                  'amount',
                ],
                {
                  'ownerId': (dynamic row) => () {
                        Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (pageContext) => Scaffold(
                                      appBar: AppBar(
                                        title: Text('Charges: ${row["name"]}'),
                                      ),
                                      body: Charges(
                                          ownerId: row["ownerId"] as int),
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
                  Expanded(child: ChargeForm(ownerId: ownerId))
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
class ChargeForm extends StatefulWidget {
  final int ownerId;

  const ChargeForm({Key key, this.ownerId}) : super(key: key);
  @override
  ChargeFormState createState() {
    return ChargeFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class ChargeFormState extends State<ChargeForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<ChargeFormState>.
  final _formKey = GlobalKey<FormState>();
  bool enabled = true;

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
                labelText: 'Confirm team id to charge the team now.'),
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
                        setEnable(true);
                        print(widget.ownerId);
                        AdminManager.instance.chargeTeam(widget.ownerId);
                      }
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
