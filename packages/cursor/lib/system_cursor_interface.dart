import 'dart:async';

import 'package:cursor/system_cursor_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class SystemCursorPlatform extends PlatformInterface {
  /// Constructs a Cursor Platform.
  SystemCursorPlatform() : super(token: _token);

  static final Object _token = Object();

  static SystemCursorPlatform _instance = SystemCursorChannel();

  /// The default instance of [SystemCursorPlatform] to use.
  /// Defaults to [SystemCursorChannel].
  static SystemCursorPlatform get instance => _instance;

  static set instance(SystemCursorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> hide() =>
      throw UnimplementedError('hide() has not been implemented.');

  Future<void> show() =>
      throw UnimplementedError('openWebView() has not been implemented.');
}
