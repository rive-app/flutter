import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show required;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_window_utils.dart';

/// The interface that implementations of window_utils must implement.
///
/// Platform implementations should extend this class rather than implement it as `url_launcher`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [UrlLauncherPlatform] methods.
abstract class WindowUtilsPlatform extends PlatformInterface {
  /// Constructs a UrlLauncherPlatform.
  WindowUtilsPlatform() : super(token: _token);

  static final Object _token = Object();

  static WindowUtilsPlatform _instance = MethodChannelWindowUtils();

  /// The default instance of [MethodChannelWindowUtils] to use.
  /// Defaults to [MethodChannelUrlLauncher].
  static WindowUtilsPlatform get instance => _instance;

  static set instance(WindowUtilsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /*
   * API
   */

  Future<String> openWebView(String key, String url,
          {Offset offset, Size size, String jsMessage = ''}) =>
      throw UnimplementedError('openWebView() has not been implemented.');

  Future<bool> closeWebView(String key) =>
      throw UnimplementedError('closeWebView() has not been implemented.');

  Future<bool> resizeWindow(String key, Size size) =>
      throw UnimplementedError('resizeWindow() has not been implemented.');

  Future<bool> moveWindow(String key, Offset offset) =>
      throw UnimplementedError('moveWindow() has not been implemented.');

  Future<int> keyIndex(String key) =>
      throw UnimplementedError('keyIndex() has not been implemented.');

  Future<int> windowCount() =>
      throw UnimplementedError('windowCount() has not been implemented.');

  Future<String> lastWindowKey() =>
      throw UnimplementedError('lastWindowKey() has not been implemented.');

  Future<Map> getWindowStats([String key]) =>
      throw UnimplementedError('getWindowStats() has not been implemented.');

  Future<Size> getWindowSize([String key]) =>
      throw UnimplementedError('getWindowSize() has not been implemented.');

  Future<Offset> getWindowOffset([String key]) =>
      throw UnimplementedError('getWindowOffset() has not been implemented.');

  String generateKey([int length = 10]) =>
      throw UnimplementedError('generateKey() has not been implemented.');

  Future<bool> showTitleBar() =>
      throw UnimplementedError('showTitleBar() has not been implemented.');

  Future<bool> hideTitleBar() =>
      throw UnimplementedError('hideTitleBar() has not been implemented.');

  Future<bool> closeWindow() =>
      throw UnimplementedError('closeWindow() has not been implemented.');

  /// [Windows] Only
  Future<bool> minWindow() =>
      throw UnimplementedError('minWindow() has not been implemented.');

  /// [Windows] Only
  Future<bool> maxWindow() =>
      throw UnimplementedError('maxWindow() has not been implemented.');

  Future<bool> centerWindow() =>
      throw UnimplementedError('centerWindow() has not been implemented.');

  Future<bool> setPosition(Offset offset) =>
      throw UnimplementedError('setPosition() has not been implemented.');

  Future<bool> setSize(Size size) =>
      throw UnimplementedError('setSize() has not been implemented.');

  Future<bool> startDrag() =>
      throw UnimplementedError('startDrag() has not been implemented.');

  /// [Windows] Only
  Future<bool> startResize(DragPosition position) =>
      throw UnimplementedError('startResize() has not been implemented.');

  Future<bool> windowTitleDoubleTap() => throw UnimplementedError(
      'windowTitleDoubleTap() has not been implemented.');

  /// [MacOS] Only
  Future<int> childWindowsCount() =>
      throw UnimplementedError('childWindowsCount() has not been implemented.');

  /// Size of Screen that the current window is inside
  Future<Size> getScreenSize() async =>
      throw UnimplementedError('getScreenSize() has not been implemented.');

  Future<bool> hideCursor() =>
      throw UnimplementedError('hideCursor() has not been implemented.');

  Future<bool> showCursor() =>
      throw UnimplementedError('showCursor() has not been implemented.');

  Future<bool> setCursor(CursorType cursor,
          {MacOSCursorType macOS, WindowsCursorType windows}) =>
      throw UnimplementedError('setCursor() has not been implemented.');

  Future<bool> addCursorToStack(CursorType cursor,
          {MacOSCursorType macOS, WindowsCursorType windows}) =>
      throw UnimplementedError('addCursorToStack() has not been implemented.');

  Future<bool> removeCursorFromStack() => throw UnimplementedError(
      'removeCursorFromStack() has not been implemented.');

  Future<int> mouseStackCount() =>
      throw UnimplementedError('mouseStackCount() has not been implemented.');

  Future<bool> resetCursor() =>
      throw UnimplementedError('resetCursor() has not been implemented.');

  String _getCursor(CursorType cursor, MacOSCursorType macOS,
          WindowsCursorType windows) =>
      throw UnimplementedError('openWebView() has not been implemented.');
}
