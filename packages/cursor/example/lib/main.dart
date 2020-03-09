import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:cursor/system_cursor.dart';
import 'package:cursor/cursor_view.dart';
import 'package:provider/provider.dart';

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

class MainBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        onEnter: (details) {
          Cursor.change(
              context,
              (context) =>
                  Container(width: 20, height: 20, color: Colors.green));
        },
        onExit: (details) {
          Cursor.reset(context);
        },
        child: Container(width: 100, height: 100, color: Colors.red),
      ),
    );
  }
}
