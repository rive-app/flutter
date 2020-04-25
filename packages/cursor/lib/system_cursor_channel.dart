import 'dart:async';

import 'package:cursor/system_cursor_interface.dart';
import 'package:flutter/services.dart';

class SystemCursorChannel extends SystemCursorPlatform {
  static const MethodChannel _channel =
      const MethodChannel('plugins.rive.app/cursor');

  @override
  Future<void> hide() async => await _channel.invokeMethod('hide');

  @override
  Future<void> show() async => await _channel.invokeMethod('show');
}
