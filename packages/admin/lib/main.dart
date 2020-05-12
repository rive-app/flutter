import 'package:admin/login.dart';
import 'package:admin/manager.dart';
import 'package:admin/signout.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/models/user.dart';

import 'admin_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rive Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: AdminManager.instance.ready,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data) {
            return StreamBuilder<RiveUser>(
              stream: AdminManager.instance.user,
              builder: (context, snapshot) {
                var user = snapshot.hasData ? snapshot.data : null;
                return user == null
                    ? Center(
                        child: Login(),
                      )
                    : user.isAdmin
                        ? AdminView()
                        : Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 500,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: 20),
                                  Text(
                                      'You do not have access to use this tool.'),
                                  Signout(),
                                ],
                              ),
                            ),
                          );
              },
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
