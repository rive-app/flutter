import 'package:flutter/material.dart';

import 'package:rive_api/api.dart' as rive;
import 'package:rive_api/auth.dart' as rive;

void main() async {
  // print('one');
  // var data = LocalData.make('rive');
  // print('two');
  // var ok = await data.initialize();
  // print('three');
  // {
  //   var array = Uint8List.fromList([7, 31, 82]);
  //   var wrote = await data.save('test', array);
  //   var read = await data.load('test');
  //   print('$ok $wrote $read');
  // }
  // {
  //   var array = Uint8List.fromList([2, 12, 20]);
  //   var wrote = await data.save('cells', array);
  //   var read = await data.load('cells');
  //   print('$ok $wrote $read');
  // }

  var api = rive.RiveApi();
  bool ready = await api.initialize();
  if (ready) {
    var auth = rive.RiveAuth(api);
    var result = await auth.login('test', 'one');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Container(),
      ),
    );
  }
}
