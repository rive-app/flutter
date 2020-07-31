import 'package:admin/manager.dart';
import 'package:flutter/material.dart';
import 'package:admin/tables.dart';

class Users extends StatefulWidget {
  final int ownerId;

  const Users({Key key, this.ownerId = 0}) : super(key: key);

  @override
  _UsersState createState() => _UsersState();
}

class _UsersState extends State<Users> {
  dynamic userList;

  Future<void> loadUsers() async {
    dynamic users = await AdminManager.instance.listUsers();
    setState(() {
      userList = users;
    });
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    if (userList != null) {
      var table = DataTableView(
          'Users',
          userList,
          const [
            'ownerId',
            'email',
            'name',
            'username',
            'isAdmin',
            'isVerified',
          ],
          {
            'ownerId': (dynamic row) => () {
                  Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (pageContext) => Scaffold(
                                appBar: AppBar(
                                  title: Text('Users: ${row["name"]}'),
                                ),
                                body: Users(ownerId: row["ownerId"] as int),
                              ))).then((value) => loadUsers());
                }
          },
          filter: (dynamic row) =>
              (widget.ownerId == 0) || row['ownerId'] as int == widget.ownerId);
      if (widget.ownerId == 0) {
        return table;
      } else {
        return Column(
          children: [
            Expanded(child: table),
            Expanded(
                child: DeleteForm(
              ownerId: widget.ownerId,
              callback: () {
                print('callback');
                Navigator.pop(context);
              },
            ))
          ],
        );
      }
    } else {
      return const CircularProgressIndicator();
    }
  }
}

// Create a Form widget.
class DeleteForm extends StatefulWidget {
  final int ownerId;
  final Function callback;

  const DeleteForm({Key key, this.ownerId, this.callback}) : super(key: key);
  @override
  DeleteFormState createState() {
    return DeleteFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class DeleteFormState extends State<DeleteForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<DeleteFormState>.
  final _formKey = GlobalKey<FormState>();
  bool enabled = true;
  String error = 'no error, wow such work';

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
                labelText: 'Confirm owner id to delete the owner.'),
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
                  ? () async {
                      setEnable(false);
                      // Validate returns true if the form is valid, or false
                      // otherwise.
                      if (_formKey.currentState.validate()) {
                        // If the form is valid, display a Snackbar.
                        Scaffold.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')));
                        try {
                          await AdminManager.instance
                              .deleteUser(widget.ownerId);
                          Scaffold.of(context).showSnackBar(
                              const SnackBar(content: Text('Done')));
                          widget.callback();
                        } on Exception catch (e) {
                          setState(() {
                            error = e.toString();
                          });
                          Scaffold.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed')));
                        } finally {
                          setEnable(true);
                        }
                      }
                      setEnable(true);
                    }
                  : null,
              child: const Text('Delete Now!'),
            ),
          ),
          Text(error)
        ],
      ),
    );
  }
}
