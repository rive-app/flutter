import 'package:flutter/material.dart';

import 'package:cursor/cursor_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CursorView(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Custom Flutter Cursor'),
            ),
            body: MainBody()),
      ),
    );
  }
}

class MainBody extends StatefulWidget {
  @override
  _MainBodyState createState() => _MainBodyState();
}

class _MainBodyState extends State<MainBody> {
  CursorInstance _custom = null;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        onEnter: (details) {
          _custom?.remove();
          _custom = Cursor.change(
              context,
              (context) =>
                  Container(width: 20, height: 20, color: Colors.green));
        },
        onExit: (details) {
          _custom?.remove();
          _custom = null;
        },
        child: Container(width: 100, height: 100, color: Colors.red),
      ),
    );
  }
}
