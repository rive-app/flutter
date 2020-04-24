import 'dart:async';
import 'dart:ui';
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:window_utils_platform_interface/window_utils_platform_interface.dart';

import 'package:window_utils_web/browser.dart' as browser;

/// The web implementation of [WindowUtilsPlatform].
///
/// This class implements (or stubs out) `package:window_utils` functionality for the web.
class WindowUtilsPlugin extends WindowUtilsPlatform {
  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith(Registrar registrar) {
    WindowUtilsPlatform.instance = WindowUtilsPlugin();
  }

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> hideTitleBar() {
    print('Calling web version of hideTitleBar');
    return Future.value(true);
  }

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> setSize(Size size) {
    print('Calling web version of setSize');
    return Future.value(true);
  }

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> startDrag() => Future.value(true);

  /// Stubbed out for web; does nothing except return the zero offset
  @override
  Future<Offset> getWindowOffset([String key]) => Future.value(Offset.zero);

  /// Stubbed out for web; does nothing except return the zero offset
  @override
  Future<Size> getWindowSize([String key]) => Future.value(Size(
        browser.width.toDouble(),
        browser.height.toDouble(),
      ));

  /// Stubbed out for web; does nothing except return an empty string
  @override
  Future<String> openWebView(
    String key,
    String url, {
    Offset offset,
    Size size,
    String jsMessage = '',
  }) {
    // See https://github.com/flutter/flutter/issues/51461 for reference.
    final target = browser.standalone ? '_top' : '';
    final base = html.window.open(url, target);
    return Future.value('');
  }

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> closeWebView(String key) => Future.value(true);
}
