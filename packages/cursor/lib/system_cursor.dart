import 'dart:async';
import 'package:cursor/system_cursor_interface.dart';

Future<void> hide() => SystemCursorPlatform.instance.hide();

Future<void> show() => SystemCursorPlatform.instance.show();
