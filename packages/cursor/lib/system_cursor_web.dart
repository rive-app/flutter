import 'dart:async';
import 'dart:html' as html;

import 'package:cursor/system_cursor_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class CursorPlugin extends SystemCursorPlatform {
  static void registerWith(Registrar registrar) {
    print('Registering cursor plugin for web');
    SystemCursorPlatform.instance = CursorPlugin();
  }

  @override
  Future<void> hide() async => html.document.querySelector('flt-glass-pane')
    ..style.cursor = 'none';

  @override
  Future<void> show() async =>
      html.document.querySelector('flt-glass-pane').style.cursor = 'default';
}
