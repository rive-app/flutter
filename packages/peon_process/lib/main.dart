import 'dart:async';

import 'package:flutter/material.dart';
import 'package:peon/peon.dart';
import 'package:peon_process/src/tasks/flare_to_rive.dart';
import 'package:peon_process/src/tasks/rive_coop_to_png.dart';
import 'package:peon_process/src/tasks/svg_to_rive.dart';

void main() {
  runZoned(() {
    final registeredTasks = <String, Task Function(Map<String, dynamic>)>{};
    registeredTasks['ping'] = PingTask.fromData;
    registeredTasks['echo'] = EchoTask.fromData;
    registeredTasks['svgtorive'] = SvgToRiveTask.fromData;
    registeredTasks['flaretorive'] = FlareToRiveTask.fromData;
    registeredTasks['rivetopng'] = RiveCoopToPng.fromData;

    loop(getQueue, registeredTasks);
  }, onError: (dynamic e, dynamic s) {
    print('Me not that kind of orc!\nError: $e\nStackTrace: $s');
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peon',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'I am working'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'I am very busy',
            ),
          ],
        ),
      ),
    );
  }
}
