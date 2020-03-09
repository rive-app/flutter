import 'dart:async';

import 'package:flutter/services.dart';

class SystemCursor {
  static const MethodChannel _channel = const MethodChannel('cursor');

  static Future<void> hide() async {
    await _channel.invokeMethod('hide');
  }

  static Future<void> show() async {
    await _channel.invokeMethod('show');
  }
}
