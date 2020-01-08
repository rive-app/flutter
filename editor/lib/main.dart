import 'package:flutter/material.dart';
import 'package:rive_core/node.dart';
import 'package:cursor/cursor_view.dart';
import 'widgets/hierarchy.dart';
import 'widgets/resize_panel.dart';

import 'package:window_utils/window_utils.dart';
// import 'package:rive_core/rive_file.dart';
// import 'package:core/coop/connect_result.dart';

// var file = RiveFile("102:15468");
Node node;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => WindowUtils.hideTitleBar(),
  );
  // print("CONNECTING");
  // file.connect('ws://localhost:8000/').then((result) {
  //   // if(file.isAvailable){

  //   // }
  //   print("CONNECTED $result");
  //   if (result != ConnectResult.connected) {
  //     return;
  //   }
  //   node = file.add(Node()..name = 'test');
  //   node.name = 'My Shiny Node';
  //   file.captureJournalEntry();
  //   runApp(MyApp());
  // });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Editor(),
      ),
    );
  }
}

class Editor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CursorView(
      child: Column(
        children: [
          Container(
            height: 39,
            color: Color.fromRGBO(50, 50, 50, 1.0),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) {
                        WindowUtils.startDrag();
                      }),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(width: 95),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) {
                        print("HIT BUTTON");
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        color: Color.fromRGBO(60, 60, 60, 1.0),
                        child: Center(
                          child: Text(
                            'Testing File',
                            style: TextStyle(
                                fontFamily: 'Roboto-Regular',
                                fontSize: 13,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 42,
            color: Color.fromRGBO(60, 60, 60, 1.0),
          ),
          Expanded(
            child: Row(
              children: [
                ResizePanel(
                  direction: ResizeDirection.horizontal,
                  side: ResizeSide.end,
                  min: 300,
                  max: 500,
                  child: Container(
                    color: Color.fromRGBO(50, 50, 50, 1.0),
                    child: ExampleTreeView(),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      ResizePanel(
                        direction: ResizeDirection.vertical,
                        side: ResizeSide.end,
                        min: 100,
                        max: 500,
                        child: Container(
                          color: Color.fromRGBO(40, 40, 40, 1.0),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Color.fromRGBO(29, 29, 29, 1.0),
                        ),
                      ),
                      ResizePanel(
                        direction: ResizeDirection.vertical,
                        side: ResizeSide.start,
                        min: 100,
                        max: 500,
                        child: Container(
                          color: Color.fromRGBO(40, 40, 40, 1.0),
                        ),
                      ),
                    ],
                  ),
                ),
                ResizePanel(
                  direction: ResizeDirection.horizontal,
                  side: ResizeSide.start,
                  min: 300,
                  max: 500,
                  child: Container(
                    color: Color.fromRGBO(50, 50, 50, 1.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
