import 'package:admin/manager.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';

class ApiChoser extends StatefulWidget {
  @override
  _ApiChoserState createState() => _ApiChoserState();
}

class _ApiChoserState extends State<ApiChoser> {
  final _formKey = GlobalKey<FormState>();

  final hostController = TextEditingController();

  void updateHost() {
    setState(() {
      RiveApi().host = hostController.text;
      AdminManager.instance.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: ListView(children: [
          const Text('Current Server'),
          Text(RiveApi().host),
          TextFormField(
            decoration: const InputDecoration(
                labelText:
                    "New Server e.g 'https://slimer.rive.app', 'http://127.0.0.1:3000'"),
            controller: hostController,
            validator: (value) {
              if (value.isEmpty) {
                return 'Enter new value';
              }
              return null;
            },
          ),
          RaisedButton(
              child: const Text('update'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  updateHost();
                }
              })
        ]),
      ),
    );
  }
}
